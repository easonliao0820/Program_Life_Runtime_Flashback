// Only the official GIS library handles Google credentials; never persist or log them.
(() => {
    if (window.PLGoogleLogin) return;
    let pending = null;
    let library = null;
    function load() {
        if (window.google?.accounts?.id) return Promise.resolve();
        if (library) return library;
        library = new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = 'https://accounts.google.com/gsi/client';
            script.async = true;
            const timer = setTimeout(() => fail(), 15000);
            function fail() { clearTimeout(timer); script.remove(); library = null; reject(new Error('gis_load')); }
            script.onerror = fail;
            script.onload = () => { clearTimeout(timer); resolve(); };
            document.head.appendChild(script);
        });
        return library;
    }
    function close() {
        if (!pending) return;
        clearTimeout(pending.timer);
        pending.panel.remove();
        pending = null;
    }
    window.PLGoogleLogin = {
        close,
        show(clientId, callback) {
            close();
            const panel = document.createElement('div');
            panel.style.cssText = 'position:fixed;inset:0;z-index:10000;display:flex;align-items:center;justify-content:center;background:#0009';
            const box = document.createElement('div');
            box.style.cssText = 'background:white;color:#222;padding:28px;border-radius:12px;max-width:90vw;text-align:center';
            box.setAttribute('role', 'dialog');
            box.setAttribute('aria-label', 'Google 登入');
            const status = document.createElement('p');
            status.textContent = '正在載入 Google 登入…';
            const button = document.createElement('div');
            const cancel = document.createElement('button');
            cancel.textContent = '取消';
            cancel.style.cssText = 'margin-top:20px;padding:8px 24px;cursor:pointer';
            box.append(status, button, cancel);
            panel.append(box);
            document.body.append(panel);
            const attempt = {panel, timer: null};
            pending = attempt;
            function finish(kind, value) {
                if (pending !== attempt) return;
                close();
                callback(kind, value);
            }
            cancel.onclick = () => finish('error', 'Google 登入已取消');
            cancel.focus();
            attempt.timer = setTimeout(() => finish('error', 'Google 登入等待逾時，請重試'), 180000);
            load().then(() => {
                if (pending !== attempt) return;
                google.accounts.id.initialize({
                    client_id: clientId, auto_select: false, ux_mode: 'popup',
                    callback: response => {
                        if (typeof response.credential !== 'string' || !response.credential) {
                            finish('error', 'Google 未提供登入憑證');
                            return;
                        }
                        finish('token', response.credential);
                    }
                });
                status.textContent = '請使用下方 Google 官方按鈕登入';
                google.accounts.id.renderButton(button, {type: 'standard', theme: 'outline', size: 'large', width: 260});
            }).catch(() => finish('error', 'Google 登入元件載入失敗，請檢查網路後重試'));
        }
    };
})();
