// Fresh Worker per execution. This is responsiveness isolation, not a security boundary.
(() => {
    if (window.PLPython) return;
    let active = null, serial = 0;
    const completed = new Map();
    function error(type, message) {
        return JSON.stringify({ok:false, passed:false, stdout:'', flags:{}, message:'', error:{type,message,line:0,text:''}});
    }
    function workerMain() {
        self.onmessage = async ({data}) => {
            try {
                importScripts(data.base + 'pyodide.js');
                const py = await loadPyodide({indexURL:data.base});
                py.runPython(data.harness);
                const run = py.globals.get('run_request_json');
                self.postMessage({kind:'ready'});
                const output = run(data.request);
                run.destroy();
                self.postMessage({kind:'result', output});
            } catch (_) {
                self.postMessage({kind:'failure'});
            }
        };
    }
    function finish(job, output) {
        if (active !== job) return;
        clearTimeout(job.timer);
        if (job.worker) job.worker.terminate();
        if (job.url) URL.revokeObjectURL(job.url);
        active = null;
        completed.set(job.id, output);
    }
    window.PLPython = {
        start(base, harness, request, runMs, loadMs) {
            if (active) return -1;
            completed.clear();
            const job = {id:++serial, worker:null, url:null, timer:null, ready:false};
            active = job;
            try {
                job.url = URL.createObjectURL(new Blob(['(' + workerMain.toString() + ')();'], {type:'text/javascript'}));
                job.worker = new Worker(job.url);
                job.timer = setTimeout(() => finish(job, error('EnvironmentError','Python 載入逾時，請檢查網路後重試。')), loadMs);
                job.worker.onmessage = ({data}) => {
                    if (active !== job) return;
                    if (data.kind === 'ready' && !job.ready) {
                        job.ready = true;
                        clearTimeout(job.timer);
                        job.timer = setTimeout(() => finish(job,error('TimeoutError','執行超過 10 秒，已停止。')),runMs);
                    } else if (data.kind === 'result' && job.ready) {
                        finish(job, typeof data.output === 'string' && data.output.length <= 1048576 ? data.output : error('OutputLimitError','執行結果過大。'));
                    } else if (data.kind === 'failure') {
                        finish(job,error('EnvironmentError','Python 執行環境失敗，請重試。'));
                    }
                };
                job.worker.onerror = event => {event.preventDefault();finish(job,error('EnvironmentError','Python Worker 無法執行，請檢查網路或瀏覽器設定。'));};
                job.worker.onmessageerror = () => finish(job,error('EnvironmentError','Python 回應無法讀取。'));
                job.worker.postMessage({base,harness,request});
            } catch (_) { finish(job,error('EnvironmentError','無法建立 Python Worker。')); }
            return job.id;
        },
        take(id) {const value=completed.get(id)||'';completed.delete(id);return value;},
        cancel(id) {if(active && active.id===id) finish(active,error('CancelledError','已停止執行。'));}
    };
})();
