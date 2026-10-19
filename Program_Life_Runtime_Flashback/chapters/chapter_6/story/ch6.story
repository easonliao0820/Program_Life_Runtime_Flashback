# 第六章　告別　｜　結局判定
# 【設計】遊戲在每一個關卡都會記錄玩家是否「第一次就通過」（不看提示、沒有出錯）。
#   completion = first_try_passed / total_levels
#   completion >= 0.8 → 結局二；否則 → 結局一（門檻在 ChapterRegistry.ENDING_THRESHOLD）
# 兩個結局的回憶遊戲順序相反：結局一由簡單到困難；結局二由困難到簡單（最後一題回到人生的第一行程式）。

@bg lake_sunset
@orb mood fading
（很多很多年以後。）
（你的頭髮白了，走路慢了，派森的光也開始忽明忽暗。）
@ending
