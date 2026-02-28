;; init.el -- The full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file includes all my customized configuration which works out of box.
;; It will install missing packages automatically.

;;; Code:

;; Consts
(defconst nerd-font "FiraCode Nerd Font Mono-13")
(defconst main-font "FiraCode Nerd Font Mono-13")
(defconst skip-chars '(?_ ?- ?\\))
(defconst unimportant-buffers
  '("*Help*" "*Warning*" "*Messages*" "*Backtrace*" "\*eldoc")
  "List of unimportant buffers.")
(defvar recentf-exclude-files
  '("^/ssh:" "^/sudo:" "~/.emacs.d/.cache/.*" "recentf$" "/tmp/.*"))

;; Path
(defun init/expand-and-create (NAME)
  (let ((file (expand-file-name NAME user-emacs-directory)))
    (unless (file-exists-p file)
      (if (string= (substring file -1) "/")
	  (make-directory file t) ;; Create nonexsist parent directory
	(write-region "" nil file nil 'nomessage)))
    file))

(setq custom-file (init/expand-and-create "custom.el"))
(load custom-file)
(add-to-list 'load-path (init/expand-and-create "lisp/"))

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

(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 90))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 75)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）
(add-to-list 'default-frame-alist `(font . ,main-font))
(set-fontset-font t '(?\u4e00 . ?\u9fff) (font-spec :name "思源黑体" :lang 'zh))
(set-fontset-font t '(?\U0001f300 . ?\U0001f9ff) (font-spec :name "Segoe-UI-EMoji"))


(global-set-key (kbd "<ESC><ESC><ESC>") nil)
(global-set-key (kbd "<escape>") 'keyboard-quit)
(define-key minibuffer-mode-map (kbd "<escape>") 'minibuffer-keyboard-quit)

;; Debug
(defun open-init-file()
(defun open-init-file ()
  "Open init.el."
  (interactive)
  (find-file (init/expand-and-create "init.el")))
(global-set-key (kbd "C-,") 'open-init-file)

;; Packages
(require 'package)
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq package-archives '(("gnu"    . "https://mirrors.lzu.edu.cn/elpa/gnu/")
                         ("nongnu" . "https://mirrors.lzu.edu.cn/elpa/nongnu/")
                         ("melpa"  . "https://mirrors.lzu.edu.cn/elpa/melpa/")))
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

;; Persistence
(savehist-mode 1)
(use-package recentf
  :custom
  (recentf-max-saved-items 50)
  :config
  (recentf-mode)
  (dolist (itm recentf-exclude-files)
    (add-to-list 'recentf-exclude itm))
  )

;; Keybindings

;; Preparations
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
  "删除光标前所有空白字符，直到第一个非空白字符.
删除后如果光标不在行首，则保留原有的一个空白字符(而非统一空格)"
  (interactive "P") ; 支持交互式调用
  (when (eq (point) (line-beginning-position))
    (delete-char -1))
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

;; Core kbds

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

  "M-[" 'evil-jump-backward
  "M-]" 'evil-jump-forward

  "K" 'scroll-down
  "J" 'scroll-up
  "M-j" 'scroll-other-window
  "M-k" 'scroll-other-window-down)

(general-define-key
 :keymaps 'override
 :states '(normal insert)
  "S-<backspace>" 'delete-whitespace-before-point)

(normal-def
  :keymaps 'prog-mode-map
  "C-/" 'comment-dwim
  "M-/" 'comment-line
  "C-e" 'eval-smart) ; Prog

(leader-def
  "S" 'server-edit
  "b" 'switch-to-buffer
  "SPC" '(lambda () (interactive) (dired "."))
  "f" 'find-file
  "r" 'recentf
  "g" 'magit
  "o f" 'org-roam-node-find)

(normal-def
  :keymaps 'dired-mode-map
  "H" 'dired-up-directory)
(normal-def
  :keymaps 'ibuffer-mode-map
  "H" 'ibuffer-mark-forward)

(defun kill-unimportant-buffer-and-windows ()
  "Kill unimportant buffers and windows.
List of unimportant buffers see `'"
  (interactive)
  (dolist (buf-name unimportant-buffers)
    (let ((bufs (match-buffers buf-name)))
      (dolist (buf bufs)
	(when (buffer-live-p buf)
          ;; Delete windows showing this buffer
          (dolist (window (get-buffer-window-list buf nil t))
            (delete-window window))
          ;; Kill the buffer
          (kill-buffer buf))))))

;; (defun smart-other-window ()
;;   (interactive)
;;   ())
(normal-def
  :keymaps 'override
  :prefix "z"
  "q" 'kill-unimportant-buffer-and-windows
  "k" 'delete-window
  "K" 'kill-buffer-and-window
  "1" 'delete-other-windows
  "2" 'split-window-below
  "3" 'split-window-right
  "z" 'other-window

  "b" 'switch-to-buffer-other-window
  "d" 'dired-other-window
  "f" 'find-file-other-window)
(general-define-key
 :keymaps 'global)

;; Evil enhancements

(use-package evil-collection
  :ensure t
  :after evil
  :init
  (setq evil-want-keybinding nil)
  :config
  (evil-collection-init)
  (evil-define-key '(normal motion) dired-mode-map
    "H" 'dired-up-directory)
  (evil-define-key '(normal motion) ibuffer-mode-map
    "SPC" 'ibuffer-mark-forward
    "o" 'ibuffer-visit-buffer-other-window)
  )

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
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  ;;(completion-pcm-leading-wildcard t) ;; Emacs 31: partial-completion behaves like substring
  ;; Orderless:
  (orderless-matching-styles '(orderless-regexp
			       orderless-literal
			       orderless-initialism))
  )
(use-package corfu
  :ensure t
  :custom
  (tab-always-indent 'complete)
  (completion-cycle-threshold nil)
  (corfu-cycle t)
  (corfu-preview-current 'insert)
  (corfu-preselect 'prompt)
  (corfu-echo-delay '(0.5 . 0.1))
  :general
  (:keymaps 'corfu-map
	    "RET" (lambda () (interactive) (corfu-insert) (newline-and-indent))
	    "TAB" 'corfu-next
	    [backtab] 'corfu-previous
	    "M-j" 'corfu-next
	    "M-k" 'corfu-previous)
  :init
  (global-corfu-mode)
  :config
  (corfu-echo-mode)
  (set-face-attribute 'corfu-echo nil
		      :foreground (doom-darken 'base8 0.1))
  ;; Orderless
  (add-hook 'corfu-mode-hook
            (lambda ()
              (setq-local completion-styles '(orderless basic)
			  orderless-matching-styles '(orderless-literal
						      orderless-initialism)
                          completion-category-overrides nil
                          completion-category-defaults nil))))
(use-package nerd-icons-corfu
  :after nerd-icons
  :ensure t
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
(defun init/vertico-tab ()
  "Help function for `TAB' of vertico completion."
  (interactive)
  (let ((prev (minibuffer-contents)))
    (minibuffer-complete)
    (if (string= prev (minibuffer-contents))
	(vertico-next))))
;; Minibuffer
(use-package vertico
  :ensure t
  :custom
  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  (completion-show-inline-help nil) ; To prevent inline-help from blocking `vertico-next'
  (vertico-count 13)		    ; Number of candidates to display
  (vertico-resize t)
  (vertico-cycle t) ; Go from last to first candidate and first to last (cycle)?
  :general
  (:keymaps 'vertico-map
	    "TAB" 'init/vertico-tab
	    "M-TAB" 'vertico-insert
	    "RET" 'vertico-directory-enter
	    "DEL" 'vertico-directory-delete-char
	    "S-DEL" 'vertico-directory-delete-word
	    [backtab] 'vertico-previous
	    "M-k" 'vertico-next
	    "M-j" 'vertico-previous
	    [up] 'previous-history-element
	    [down] 'next-history-element
            )
  :init
  (vertico-mode)
  (vertico-reverse-mode))
(use-package consult
  :ensure t
  :config
  (normal-def
    "/" 'consult-line
    "?" 'consult-line-multi)
  (defun noct-consult-line-evil-history (&rest _)
    "Add latest `consult-line' search pattern to the evil search history ring.
This only works with orderless and for the first component of the search. Source: https://github.com/minad/consult/issues/318#issuecomment-882067919"
    (let ((pattern (nth 1 (orderless-compile (car consult--line-history)))))
      (add-to-history 'regexp-search-ring pattern regexp-search-ring-max)
      (setq evil-ex-search-pattern (list pattern t t))
      (setq evil-ex-search-direction 'forward)
      (when evil-ex-search-persistent-highlight
        (evil-ex-search-activate-highlight evil-ex-search-pattern))))
  (defun my-consult-line-evil-history (&rest _)
    (when consult--line-history
                (add-to-history
                 'regexp-search-ring ;; or search-ring
                 (car consult--line-history)
                 regexp-search-ring-max)))
  (advice-add #'consult-line :after #'noct-consult-line-evil-history))
(use-package marginalia
  :ensure t
  :general
  (:keymaps '(minibuffer-mode-map completion-list-mode-map)
         "M-m"  'marginalia-cycle)
  :init
  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))
(defun init/add-find-file-sudo (&rest _)
  "Toggle '/sudo::' prefix of file name."
  (general-def :keymaps 'minibuffer-mode-map "M-s" (lambda ()
						(interactive)
						(let* ((prompt (minibuffer-contents))
						       (re "^/sudo:.*?:" ))
						  (delete-minibuffer-contents)
						  (if (string-match-p re prompt)
						      (progn
							(insert (replace-regexp-in-string re "" prompt)))
						    (progn
						      (insert (concat "/sudo::" (expand-file-name prompt)))
						      ))))))

(defun init/remove-find-file-sudo (&rest _)
  "Toggle '/sudo::' prefix of file name."
  (general-def :keymaps 'minibuffer-mode-map :prefix "M-s" "" nil))
(advice-add 'read-file-name :before 'init/add-find-file-sudo)
(advice-add 'read-file-name :after 'init/remove-find-file-sudo)

;; Languages

;; Latex
(setq org-preview-latex-default-process 'dvipng)

;; Lsp
(use-package xref
  :ensure t
  :config
  (normal-def
    :keymaps 'xref--xref-buffer-mode-map
    :prefix "g"
    "D" 'xref-find-definitions
    "d" 'xref-find-definitions
    "r" 'xref-find-references
    )
  (normal-def
    :keymaps 'xref--xref-buffer-mode-map
    "j"  'xref-next-line
    "k" 'xref-prev-line
    "J"  'xref-next-group
    "K" 'xref-prev-group
   ))
(use-package eldoc
  :custom
  (eldoc-idle-delay 0.2))
(use-package eglot
  :hook
  ((rust-mode python-mode) . 'eglot-ensure)
  :config
  (normal-def
    :keymaps 'eglot-mode-map
    :state 'normal
    "<f2>" 'eglot-rename
    "C-." 'eglot-code-actions
    )
  (leader-def
    :keymaps 'eglot-mode-map
    :state 'normal
    "=" 'eglot-format
    "h h" 'eldoc-doc-buffer
    )
  (append
   '(python-mode . ("uvx" "ty" "server"))
   '(rust-mode . ("rust-analyzer" :initializationOptions
		  (:cargo (:buildScripts (:enable t))))) ; cargo.buildScripts.enable = true
   'eglot-server-programs
   ))

;; Syntax check
(use-package flycheck
  :ensure t
  :config
  (normal-def
    :keymaps 'flycheck-mode-map
    "<f8>" 'flycheck-next-error
    "S-<f8>" 'flycheck-previous-error
    )
  :hook (prog-mode . flycheck-mode))
(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :config
  (global-flycheck-eglot-mode 1))

;; Elisp
(add-hook 'emacs-lisp-mode-hook (lambda ()
				  (setq flycheck-emacs-lisp-load-path 'inherit)
				  (leader-def
				    :keymaps 'emacs-lisp-mode-map
				    :infix "h"
				    "v" 'describe-variable
				    "f" 'describe-function
				    "h" 'help-follow-symbol)
				  ))



;; Magit
(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
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
(use-package rainbow-delimiters
  :ensure t
  :hook
  (prog-mode . rainbow-delimiters-mode))
;; (use-package rainbow-mode
;;   :ensure t
;;   :hook
;;   (prog-mode . rainbow-mode))
(use-package colorful-mode
  :ensure t
  :custom
  (colorful-only-strings 'only-prog)
  (colorful-use-prefix t)
  (colorful-extra-color-keyword-functions
   '(
     colorful-add-hex-colors
     ((html-mode css-mode) . (colorful-add-color-names colorful-add-css-variables-colors))
     colorful-add-rgb-colors
     colorful-add-hsl-colors
     (latex-mode . colorful-add-latex-colors)
     ))
  :hook
  (prog-mode . colorful-mode))
(use-package nerd-icons
  :ensure t
  :custom
  (nerd-icons-font-family nerd-font))
(use-package transient
  :ensure t
  :config
  (general-def transient-map "<escape>" 'transient-quit-one))

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
