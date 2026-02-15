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
;(setq confirm-kill-emacs #'yes-or-no-p)      ; 在关闭 Emacs 前询问是否确认关闭，防止误触
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
(setq split-width-threshold 0)  ; 始终优先垂直分割（宽度阈值设为0）
(setq split-height-threshold nil) ; 禁用水平分割的高度阈值

(savehist-mode 1)                            ; （可选）打开 Buffer 历史记录保存
(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 90))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 75)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）
(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font Mono-13"))
(set-fontset-font t '(?\u4e00 . ?\u9fff) (font-spec :name "思源黑体" :lang 'zh))


(global-set-key (kbd "<ESC><ESC><ESC>") nil)
(global-set-key (kbd "<escape>") 'keyboard-quit)
(define-key minibuffer-mode-map (kbd "<escape>") 'minibuffer-keyboard-quit)

;; Debug
(defun open-init-file()
  "Open init.el"
  (interactive)
  (find-file "~/.emacs.d/init.el"))
(global-set-key (kbd "C-,") 'open-init-file)

;; Packages
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Themes
(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic nil) ; if nil, italics is universally disabled
  :config
  (load-theme 'doom-1337)
  ;; Enable flashing mode-line on errors
  ;; (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config)
  (custom-set-faces
   `(mode-line ((t (:background ,(doom-color 'base3)))))
   `(font-lock-comment-face ((t (:foreground ,(doom-color 'base7))))))
  )

;; Keybindings

; Preparations
(defun eval-smart ()
  "Smart evaluation: eval selected region if active, else eval whole buffer.
Works for Emacs Lisp (elisp) by default, can be adapted for other Lisp dialects."
  (interactive)  ; 声明为交互式函数，可通过 M-x 或快捷键调用
  (if (region-active-p)  ; 检查是否有选中的文本区域
      ;; 有选中区域：执行选中区域的代码
      (progn
	(eval-region (region-beginning) (region-end))  ; 求值选中区域
	(deactivate-mark)
	)
    ;; 无选中区域：执行整个缓冲区的代码
    (eval-buffer)))  ; 求值整个缓冲区
(defun delete-whitespace-before-point (&optional arg)
  "删除光标前所有空白字符，直到第一个非空白字符。
删除后如果光标不在行首，则保留**原有的一个空白字符**（而非统一空格）。
可选参数ARG无实际作用，仅为兼容Emacs命令习惯。"
  (interactive "P") ; 支持交互式调用
  (save-excursion   ; 保存当前光标位置，函数结束后恢复
    (let* (
           ;; 记录当前光标位置
           (original-point (point))
           ;; 移动到当前行的第一个非空白字符位置
           (first-non-whitespace (save-excursion
                                   (beginning-of-line)
                                   (skip-chars-forward " \t")
                                   (point)))
           ;; 移动到光标前第一个非空白字符的位置
           (non-whitespace-pos (save-excursion
                                 (skip-chars-backward " \t")
                                 (point)))
           ;; 获取需要保留的原始空白字符（光标前第一个空白字符）
           (original-whitespace (when (and (> original-point non-whitespace-pos)
                                           (not (eq non-whitespace-pos original-point)))
                                  (char-to-string (char-after non-whitespace-pos)))))
      
      ;; 1. 删除光标前所有空白字符（从non-whitespace-pos到original-point之间的内容）
      (when (> original-point non-whitespace-pos)
        (delete-region non-whitespace-pos original-point))
      
      ;; 2. 判断删除后光标是否在行首，若不在则保留**原有的一个空白字符**
      (when (and (> (point) first-non-whitespace) ; 光标不在行首（非空白字符起始位置）
                 (not (bolp))                     ; 光标也不是行首位置
                 original-whitespace)	 ; 存在可保留的原始空白字符
        (insert original-whitespace))))) ; 插入原始空白字符（而非空格）
(defconst skip-chars '(?_ ?-))
(defun init/evil-forward-word-begin-skip ()
  (interactive)
  (evil-forward-word-begin)
  (let* ((char (char-after (point))))
    (if (memq char skip-chars)
	(evil-forward-char))))
(defun init/evil-backward-word-begin-skip ()
  (interactive)
  (evil-backward-word-begin)
  (let* ((char (char-after (point))))
    (if (memq char skip-chars)
	(evil-backward-char))))

(use-package general
  :ensure t
  :config
  (general-evil-setup))
(use-package evil
  :ensure t
  :after general
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  (setq evil-echo-state nil)
  (setq evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (setq evil-emacs-state-modes (delq 'ibuffer-mode evil-emacs-state-modes))
  (with-eval-after-load 'evil-maps ; Remove evil's keymap for specific keys
    (define-key evil-normal-state-map (kbd "s") nil)
    (define-key evil-normal-state-map (kbd "q") nil)
    (define-key evil-motion-state-map (kbd "q") nil)
    (define-key evil-motion-state-map (kbd "SPC") nil)
    (define-key evil-motion-state-map (kbd "RET") nil)
    (define-key evil-motion-state-map (kbd "TAB") nil))
  )

; Core kbds

(general-create-definer leader-def
  :states '(normal motion)
  :keymaps 'override
  :prefix "SPC")
(general-create-definer normal-def
  :states '(normal motion))

(general-define-key
 :states '(normal visual operator)
 "0" 'back-to-indentation
 "L" 'move-end-of-line
 "H" 'back-to-indentation)
(general-define-key
 :states 'insert
 "M-w" 'init/evil-forward-word-begin-skip
 "M-b" 'init/evil-backward-word-begin-skip
 "M-l" 'evil-forward-char
 "M-h" 'evil-backward-char
 "M-j" 'evil-next-visual-line
 "M-k" 'evil-previous-visual-line)
(normal-def
  "C-q" 'evil-visual-block

  "w" 'init/evil-forward-word-begin-skip
  "b" 'init/evil-backward-word-begin-skip
  "j" 'evil-next-visual-line
  "k" 'evil-previous-visual-line

  "K" 'scroll-down
  "J" 'scroll-up
  "M-j" 'scroll-other-window
  "M-k" 'scroll-other-window-down

  "S-<backspace>" 'delete-whitespace-before-point) ; Motions

(normal-def
  :keymaps 'prog-mode-map
  "C-/" 'comment-dwim
  "M-/" 'comment-line
  "C-e" 'eval-smart) ; Prog

(leader-def
  "b" 'ibuffer
  "SPC" '(lambda () (interactive) (dired "."))
  "f" 'find-file
  "g" 'magit)
(leader-def
  :infix "h"
  "h" 'help-follow-symbol
  "v" 'describe-variable
  "f" 'describe-function
  "m" 'describe-mode)

(normal-def
  :keymaps 'dired-mode-map
  "H" 'dired-up-directory)
(normal-def
  :keymaps 'ibuffer-mode-map
  "H" 'ibuffer-mark-forward)
(normal-def
  :keymaps 'override
  :prefix "z"
  "k" 'delete-window
  "1" 'delete-other-windows
  "2" 'split-window-below
  "3" 'split-window-right
  "z" 'other-window

  "b" 'switch-to-buffer-other-window
  "d" 'dired-other-window
  "f" 'find-file-other-window)

; Evil enhancements

(use-package evil-collection
  :ensure t
  :after evil
  :init
  (setq evil-want-keybinding nil)
  :config
  (evil-collection-init))

(use-package evil-surround
  :ensure t
  :config
  (global-evil-surround-mode 1))

(use-package key-chord ;; "jj" for exit
  :ensure t
  :after evil
  :config
  (setq key-chord-two-keys-delay 0.3)
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state))

;; Windows
(use-package rotate
  :ensure t
  :config
  (normal-def "zr" 'rotate-layout))

(use-package windsize
  :ensure t
  :config
  (normal-def
    "M-<up>" 'windsize-up
    "M-<down>" 'windsize-down
    "M-<left>" 'windsize-left
    "M-<right>" 'windsize-right
    "S-<up>" 'windmove-swap-states-up
    "S-<down>" 'windmove-swap-states-down
    "S-<left>" 'windmove-swap-states-left
    "S-<right>" 'windmove-swap-states-right
    ))

;; Compeltion
(setq tab-always-indent 'complete)

(use-package corfu
  :ensure t
  :init
  (global-corfu-mode))

;; Languages

;; Magit
(use-package magit
  :ensure t
  :config
  (normal-def
    :keymaps 'magit-mode-map
    "h"  'magit-stash
    ))

;; Display
(use-package centered-cursor-mode
  :ensure t
  :demand
  :config
  (global-centered-cursor-mode))
;; IM
(use-package sis
  :ensure t
  ;; :hook
  ;; enable the /context/ and /inline region/ mode for specific buffers
  ;; (((text-mode prog-mode) . sis-context-mode)
  ;;  ((text-mode prog-mode) . sis-inline-mode))

  :config
  (cond
   ((eq system-type 'gnu/linux)  (sis-ism-lazyman-config "1" "2" 'fcitx5))
   (t                            ()))

  ;; enable the /cursor color/ mode
  (sis-global-cursor-color-mode t)
  ;; enable the /respect/ mode
  (sis-global-respect-mode t)
  ;; enable the /context/ mode for all buffers
  (sis-global-context-mode t)
  ;; enable the /inline english/ mode for all buffers
  (sis-global-inline-mode t)
  (setq sis-inline-with-english nil)
  )

;; Folding
(use-package kirigami
  :ensure t
  :config
  (normal-def
    "\\" 'kirigami-toggle-fold
    "|" 'kirigami-close-folds))

(provide 'init)
;;; init.el ends here
