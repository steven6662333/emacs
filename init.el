;; init.el -- The full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file includes all my customized configuration which works out of box.
;; It will install missing packages automatically.

;;; Code:

;; Path
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; GC
(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold normal-gc-cons-threshold)))) 

;; Basic
(setq confirm-kill-emacs #'yes-or-no-p)      ; 在关闭 Emacs 前询问是否确认关闭，防止误触
(setq use-short-answers t)
(electric-pair-mode t)                       ; 自动补全括号
(add-hook 'prog-mode-hook #'show-paren-mode) ; 编程模式下，光标在括号上时高亮另一个括号
(column-number-mode t)                       ; 在 Mode line 上显示列号
(global-auto-revert-mode t)                  ; 当另一程序修改了文件时，让 Emacs 及时刷新 Buffer
(delete-selection-mode t)                    ; 选中文本后输入文本会替换文本（更符合我们习惯了的其它编辑器的逻辑）
(setq inhibit-startup-message t)             ; 关闭启动 Emacs 时的欢迎界面
(setq make-backup-files nil)                 ; 关闭文件自动备份
(add-hook 'prog-mode-hook #'hs-minor-mode)   ; 编程模式下，可以折叠代码块
(global-display-line-numbers-mode 1)         ; 在 Window 显示行号
(tool-bar-mode -1)                           ; （熟练后可选）关闭 Tool bar
(menu-bar-mode -1)
(when (display-graphic-p) (toggle-scroll-bar -1)) ; 图形界面时关闭滚动条

(savehist-mode 1)                            ; （可选）打开 Buffer 历史记录保存
(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 90))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 75)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）

(global-set-key (kbd "<ESC><ESC><ESC>") nil)
(global-set-key (kbd "<escape>") 'keyboard-quit)
(define-key minibuffer-mode-map (kbd "<escape>") 'minibuffer-keyboard-quit)

;; Debug
(defun open-init-file()
  "Open init.el"
  (interactive)
  (find-file "~/.emacs.d/init.el"))
(ido-mode 1)
(global-set-key (kbd "C-,") 'open-init-file)

;; Repos
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Packages
(use-package key-chord
  :ensure t
  :config
  (setq key-chord-two-keys-delay 0.3)
  (key-chord-mode 1))

(defun eval-smart ()
  "Smart evaluation: eval selected region if active, else eval whole buffer.
Works for Emacs Lisp (elisp) by default, can be adapted for other Lisp dialects."
  (interactive)  ; 声明为交互式函数，可通过 M-x 或快捷键调用
  (if (region-active-p)  ; 检查是否有选中的文本区域
      ;; 有选中区域：执行选中区域的代码
      (eval-region (region-beginning) (region-end))  ; 求值选中区域
    ;; 无选中区域：执行整个缓冲区的代码
    (eval-buffera)))  ; 求值整个缓冲区

(use-package evil
  :ensure t
  :after key-chord
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  (setq evil-echo-state nil)
  :config
  (evil-mode 1)
  ;(setq evil-emacs-state-modes (delq 'ibuffer-mode evil-emacs-state-modes))
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state)
  (with-eval-after-load 'evil-maps ; Remove evil's keymap for specific keys
    (define-key evil-normal-state-map (kbd "s") nil)
    (define-key evil-motion-state-map (kbd "SPC") nil)
    (define-key evil-motion-state-map (kbd "RET") nil)
    (define-key evil-motion-state-map (kbd "TAB") nil))
  (evil-define-key '(normal visual) 'global (kbd "0") 'back-to-indentation)
  (evil-define-key '(normal visual) 'global (kbd "L") 'move-end-of-line)
  (evil-define-key '(normal visual) 'global (kbd "H") 'back-to-indentation)
  ;(evil-global-set-key 'normal (kbd "W") 'evil-forward-WORD-begin)
  ;(evil-global-set-key 'normal (kbd "w") 'evil-forward-word-begin)
  (evil-global-set-key 'normal (kbd "C-q") 'evil-visual-block)
  (evil-define-key '(normal motion) 'global (kbd "zk") 'delete-window)
  (evil-define-key '(normal motion) 'global (kbd "z1") 'delete-other-windows)
  (evil-define-key '(normal motion) 'global (kbd "z2") 'split-window-below)
  (evil-define-key '(normal motion) 'global (kbd "z3") 'split-window-right)
  (evil-define-key '(normal motion) 'global (kbd "zz") 'other-window)
  (evil-define-key '(normal motion) 'global (kbd "zb") 'ibuffer)
  (evil-define-key '(normal motion) 'global (kbd "SPC b") 'ibuffer)
  (evil-define-key '(normal motion) 'global (kbd "C-e") 'eval-smart)
  )

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init '(ibuffer)))

(use-package counsel
  :ensure t)

(use-package ivy
  :ensure t
  :after '(counsel evil)
  :init
  (ivy-mode 1)
  (counsel-mode 1)
  ; Override some kdb
  (define-key ivy-mode-map (kbd "M-j") 'ivy-next-line)
  (define-
   key ivy-mode-map (kbd "M-k") 'ivy-previous-line)
  (define-key swiper-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (evil-define-key '(normal visual) 'global (kbd "/") #'swiper-isearch)
  (evil-global-set-key 'normal (kbd "SPC f") 'counsel-find-file)
  (setq ivy-height 5)
  )

(use-package easy-theme-preview
  :ensure t)
(use-package good-scroll
  :ensure t
  :if window-system          ; 在图形化界面时才使用这个插件
  :init (good-scroll-mode))

(provide 'init)
;;; init.el ends here
