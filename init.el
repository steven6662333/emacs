;; init.el -- The full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file includes all my customized configuration which works out of box.
;; It will install missing packages automatically.

;;; Code:

;; Consts
(defconst nerd-font "FiraCode Nerd Font Mono-13")
(defconst main-font "FiraCode Nerd Font Mono-13")
(defconst skip-chars '(?_ ?- ?\\))
(defvar unimportant-buffers
  '("*Help*" "*helpful"  "*Warning*" "*Messages*" "*Backtrace*" "*complication*" "\*eldoc" "*sdcv*")
  "List of unimportant buffers.")
(defvar recentf-exclude-files
  '("^/ssh:" "^/sudo:" "~/.emacs.d/.cache/.*" "recentf$" "/tmp/.*"))

;; Helpers
(defun init/expand-and-create (name &optional dir)
  (let ((file (expand-file-name name (or dir user-emacs-directory))))
    (unless (file-exists-p file)
      (if (string= (substring file -1) "/")
	  (make-directory file t) ;; Create nonexsist parent directory
	(write-region "" nil file nil 'nomessage)))
    file))
(defun init/show-msg ()
  (with-current-buffer "*Messages*" (goto-char (point-max))))
(defmacro make-cmd (func &rest args)
  "Create an interactive command that calls FUNC with ARGS.
FUNC must be provided with #' syntax.
Usage: (global-set-key (kbd \"M-*\")
                       (make-cmd #'yas-expand-snippet \"* $0 *\"))"
  `(lambda ()
     (interactive)
     (,(cadr func) ,@args)))

;; Path
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
(when (display-graphic-p) (scroll-bar-mode -1)) ; 图形界面时关闭滚动条
(setq split-width-threshold 0)  ; 始终优先垂直分割（宽度阈值设为 0）
(setq split-height-threshold nil) ; 禁用水平分割的高度阈值
(setq server-client-instructions nil)
(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 90))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 75)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）
(setq initial-scratch-message "")
(global-auto-revert-mode) ;; Auto load every buffer if its visited file on disk is modified
;; Presistence
(setq desktop-load-locked-desktop 'check-pid)
;; FIXME: Error (frameset): Wrong type argument: number-or-marker-p, nil
(add-hook 'server-after-make-frame-hook (lambda () (ignore-errors (desktop-read) (desktop-save-mode 1)))
(add-hook 'kill-emacs-hook 'desktop-save-in-desktop-dir -100))

(add-to-list 'default-frame-alist `(font . ,main-font))
(defun init/setfont (&optional arg)
  (scroll-bar-mode -1)
  (set-fontset-font t '(?\u4e00 . ?\u9fff) (font-spec :name "思源黑体" :lang 'zh))
  (set-fontset-font t '(?（ . ?）) (font-spec :name "思源黑体"))
  (dolist (emoji-range
	'((?\u2600 . ?\u26FF)           ; Miscellaneous Symbols
          (?\u2700 . ?\u27BF)           ; Dingbats
          (?\U0001f300 . ?\U0001f5ff)   ; Miscellaneous Symbols and Pictographs
          (?\U0001f600 . ?\U0001f64f)   ; Emoticons
          (?\U0001f680 . ?\U0001f6ff)   ; Transport and Map Symbols
          (?\U0001f900 . ?\U0001f9ff)   ; Supplemental Symbols and Pictographs
          (?\U0001fa70 . ?\U0001faff)   ; Symbols and Pictographs Extended-A
          (?\u2b00 . ?\u2bff)))         ; Miscellaneous Symbols and Arrows
    (set-fontset-font t emoji-range (font-spec :name "Segoe UI Emoji"))))

(add-hook 'window-setup-hook 'init/setfont 100) ;; For startup via `emacs'
(add-hook 'server-after-make-frame-hook 'init/setfont 100) ;; For startup via `emacsclient'

(global-set-key (kbd "<ESC><ESC><ESC>") nil)
(global-set-key (kbd "<escape>") 'keyboard-quit)
(define-key minibuffer-mode-map (kbd "<escape>") 'minibuffer-keyboard-quit)

;; Debug
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
   `(font-lock-comment-face ((t (:foreground ,(doom-color 'base7)))))
   )
  )

;; Persistence
(savehist-mode 1)
(use-package recentf
  :custom
  (recentf-max-saved-items 200)
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
(defun delete-whitespace-before-point (&optional args)
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
      
      ;; 1. 删除光标前所有空白字符（从 non-whitespace-pos 到 original-point 之间的内容）
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
(defvar kbd/non-keyword-chars "()<>/\\|[]{},.?'\";:-_=+*&^%$#@!`~ （）《》？。，、“”；：【】「」！——"
  "A string consists of characters to be ignore in `kbd/extract-keywords'.


It should contain a space to handle extra space in the string to extract.
For instance, \"There're 2 spaces between A  B.\" -> \"There re 2 spaces between A B\"")
(defun kbd/extract-keywords (raw)
  "Return a string containing keywords in RAW.

The string returned is separated by space and excludes punctuations (or any other characters) listed in `kbd/non-keyword-chars'.
For instance, input \"/A Cool Book/(its-my-work)\" will return \"A Cool Book its-my-work\""
  (let (
	 (char-list nil)
	 )
    (cl-loop
     for c across raw do
     (if (seq-contains-p kbd/non-keyword-chars c)
	 (unless (eq (car char-list) ? ) (push ?  char-list))
       (push c char-list))
     )
    (string-trim
     (apply #'string (reverse char-list)))))
(defun kbd/extract-keywords-from-kill-ring (&optional arg)
  "Duplicate the latest kill in `kill-ring' and filter it with `kbd/extract-keywords'."
  (interactive)
  (let (
	(kw (kbd/extract-keywords (current-kill 0)))
	)
    (message "Copied: %s" kw)
    (kill-new kw)))


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

;; Kbd enhancements

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
(use-package defrepeater
  :ensure t)

(defmacro general/bind-around (fn &rest args)
  "Advice keybinding before calling FN and unbind it after calling or error.
The advice is added via (`advice-add' fn :around ...).
Keybinding is applyed via (`general-def' ,@args). 
The Last element of ARGS must be the command to bind.
Only ONE Keybinding is allowed."
  (let ((general-args (butlast args)))
     ;; `general-args' contains everything `general-def' required except for command
     `(advice-add ,fn :around (lambda (oldfun &rest r)
			       (general-def
				 ,@args) ;; `args' contains key and command
			       (unwind-protect
				  (apply oldfun r)
				 (general-def
				   ,@general-args nil)))) ;; Finally, unbind key
    ))

;; Core kbds

(general-create-definer leader-def
  :states '(normal motion)
  :keymaps 'override
  :prefix "SPC")
(general-create-definer normal-def
  :states '(normal motion))
(general-create-definer win-def :keymaps 'override :prefix "C-w")


(general-def
  :keymaps 'override
  "C-," 'open-init-file)
(general-define-key
 :states '(normal visual operator)
 "0" 'back-to-indentation
 "L" 'move-end-of-line
 "H" 'back-to-indentation)
(general-define-key
 :states 'insert
 "M-w" 'init/evil-forward-word-begin-skip
 "M-b" 'init/evil-backward-word-begin-skip
 "M-l" 'right-char ;; `evil-forward-char' can not get to last char of the line in `insert-state'
 "M-h" 'left-char
 "M-j" 'scroll-other-window
 "M-k" 'scroll-other-window-down
 )
(normal-def
  "C-q" 'evil-visual-block

  "w" 'init/evil-forward-word-begin-skip
  "b" 'init/evil-backward-word-begin-skip
  "j" 'evil-next-visual-line
  "k" 'evil-previous-visual-line

  "M-[" 'evil-jump-backward
  "M-]" 'evil-jump-forward
  "M-{" 'previous-buffer
  "M-}" 'next-buffer

  "K" 'scroll-down
  "J" 'scroll-up
  "M-j" 'scroll-other-window
  "M-k" 'scroll-other-window-down

  "M-s" 'query-replace
  )

(general-def
  :keymaps 'override
  :prefix "C-c"
  "/" 'evil-ex-nohighlight
  "C-e" 'kbd/extract-keywords-from-kill-ring)

(general-define-key
 :keymaps 'override
 :states '(normal insert)
  "S-<backspace>" 'delete-whitespace-before-point)
(defun a/kill-minibuffer-contents (&optional arg)
  "Kill all user input in a minibuffer, or close it if user input is empty.

If the current buffer is not a minibuffer, kill its entire contents."
  (interactive)
  (if (string= (minibuffer-contents) "")
    (minibuffer-keyboard-quit)
    (progn (kill-new (minibuffer-contents))
	 (delete-minibuffer-contents))))

(general-define-key
 :keymaps 'minibuffer-mode-map
 "S-<backspace>" 'a/kill-minibuffer-contents)
(defun comment/dwim (&optional arg)
  (interactive)
  (if (and (eq evil-state 'visual) (eq evil-visual-selection 'line))
      (call-interactively 'comment-or-uncomment-region)
    (comment-line current-prefix-arg))
  )

(normal-def
  :keymaps 'prog-mode-map
  "M-/" 'comment/dwim
  "C-e" 'eval-last-sexp)

;; Better `find-file'
(defadvice find-file (before make-directory-maybe (filename &optional wildcards) activate)
  "Create parent directory if not exists while visiting file."
  (unless (file-exists-p filename)
    (let ((dir (file-name-directory filename)))
      (unless (file-exists-p dir)
        (if (yes-or-no-p "Create parent directory?") (make-directory dir t))))))

(leader-def
  "s" (make-cmd #'jinx-mode 'toggle)
  "b" 'switch-to-buffer
  "o b" 'switch-to-buffer-other-window
  "B" 'ibuffer
  "SPC" (make-cmd #'dired ".")
  "r" 'recentf
  "f" 'find-file
  "g" 'magit
  "o t" 'org-roam-dailies-goto-date
  "o f" 'org-roam-node-find)

(normal-def
  :keymaps 'dired-mode-map
  "H" 'dired-up-directory
  "c" 'dired-do-copy
  "C" 'dired-do-compress-to
  "T" 'dired-create-empty-file)
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

;; Window
(setq other-window-scroll-default #'get-lru-window)
(setq next-screen-context-lines 2)

(use-package winner
  :config
  (winner-mode))
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
(use-package ace-window
  :ensure t)
(use-package buffer-terminator
  :ensure t
  :config
  (buffer-terminator-mode))

(defun w/other-window-mru ()
  "Select the most recently used window on this frame."
  (interactive)
  (when-let ((mru-window
              (get-mru-window
               nil nil 'not-this-one-dummy)))
    (select-window mru-window)))
(defun w/smart-other-window ()
  (interactive)
  (if (length= (window-list-1) 1)
      (switch-to-buffer (other-buffer))
    (w/other-window-mru)))
(defmacro w/with-other-window (&rest body)
  "Execute forms in BODY in the other-window."
  `(unless (one-window-p)
    (with-selected-window (other-window-for-scrolling)
      ,@body)))
(defvar w/consult-line-window nil "Window to search in `evil-search-next'.")
(defun w/consult-line-other-window ()
  "Excute `consult-line' in other-window.
See `w/with-other-window',"
  (interactive)
  (w/with-other-window
   (consult-line)))
(advice-add #'consult-line :around
	    (lambda (oldfun &rest args)
	      (setq w/consult-line-window (selected-window))
	      (apply oldfun args)))

(general-def :keymaps 'override "M-o" 'w/smart-other-window)

(general-def
  :keymaps 'override
  :states '(normal insert motion)
  :prefix "C-w"
  "w" 'ace-window
  "C-w" 'ace-window
  "o" 'other-window-prefix
  "u" (defrepeater #'winner-undo)
  "r" (defrepeater #'winner-redo))
(normal-def
  :keymaps 'override
  :prefix "z"
  "q" 'kill-unimportant-buffer-and-windows
  "k" 'delete-window
  "K" 'kill-buffer-and-window
  "1" 'delete-other-windows
  "2" 'split-window-below
  "3" 'split-window-right
  "z" 'w/smart-other-window

  "o" 'other-window-prefix
  "b" 'switch-to-buffer-other-window
  "d" 'dired-other-window
  "f" 'find-file-other-window)
(general-define-key
 :keymaps 'global)

;; Compeltion
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  ;;(completion-pcm-leading-wildcard t) ;; Emacs 31: partial-completion behaves like substring
  ;; Orderless:
  (orderless-matching-styles '(orderless-regexp
			       ;; orderless-initialism
			       orderless-literal))
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
(use-package cape
  :ensure t
  :general
  (:state 'insert
	  "C-f" #'cape-file
	  "M-/" #'cape-dabbrev))
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
	    "S-<return>" 'vertico-exit-input
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
    "?" 'w/consult-line-other-window)
  (normal-def
    :keymaps 'org-mode-map
    "gr" 'consult-org-heading)
  (general-def
    :states '(normal insert)
    "M-y" 'consult/evil-paste-pop)
  (general/bind-around 'consult--read-from-kill-ring :keymaps 'minibuffer-mode-map "M-y" 'vertico-next)
  (defun consult/evil-paste-pop (&optional arg)
    (interactive)
    (unless (memq last-command
                  '(evil-paste-after
                    evil-paste-before
                    evil-visual-paste))
      (user-error "Previous command was not an evil-paste: %s" last-command))
    (unless evil-last-paste
      (user-error "Previous paste command used a register"))
    (evil-undo-pop)
    (goto-char (nth 2 evil-last-paste))
    (setq this-command (nth 0 evil-last-paste))
    ;; use temporary kill-ring, so the paste cannot modify it
    (let ((kill-ring (list (consult--read-from-kill-ring)))
	  ;; FIXME: Except for visual mode, pasting and poping themselves works. Preview (via consult) shifts in any case.
          (kill-ring-yank-pointer kill-ring))
      (when (eq last-command 'evil-visual-paste)
	(let ((evil-no-display t))
          (evil-visual-restore)))
      (funcall (nth 0 evil-last-paste) (nth 1 evil-last-paste))
      ;; if this was a visual paste, then mark the last paste as NOT
      ;; being the first visual paste
      (when (eq last-command 'evil-visual-paste)
	(setcdr (nthcdr 4 evil-last-paste) nil)))
    )


  ;; Fix `evil-search-next'
  (defun consult-line-evil-history (&rest _)
    "Add latest `consult-line' search pattern to the evil search history ring."
    (when consult--line-history
                (add-to-history
                 'regexp-search-ring ;; or search-ring
                 (nth 1 (orderless-compile (car consult--line-history)))
                 regexp-search-ring-max)))
  (advice-add #'consult-line :after #'consult-line-evil-history)
  (defun w/evil-search-next ()
    "Repeat the last search in the correct window (see `w/consult-line-window') with `evil-search-next'."
    (interactive)
    (if (window-live-p w/consult-line-window)
	(with-selected-window w/consult-line-window
	  (evil-search-next))
      (evil-search-next)))
  (defun w/evil-search-previous ()
    "Repeat the last search in the correct window (see `w/consult-line-window') with `evil-search-next'."
    (interactive)
    (if (window-live-p w/consult-line-window)
	(with-selected-window w/consult-line-window
	  (evil-search-previous))
      (evil-search-previous)))
  (normal-def
    "n" 'w/evil-search-next
    "N" 'w/evil-search-previous
    )
  )
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

;; Sudo stuffs
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

(use-package tramp
  :general
  (:keymaps 'override
	    "C-c M-s" (make-cmd #'tramp-revert-buffer-with-sudo)))

;; Language Support

;; Text
(define-minor-mode proselint-mode
  "Toggle proselint checker of flycheck."
  :global nil
  :group 'flycheck
  :lighter ""
  (unless flycheck-mode (flycheck-mode))
  (if proselint-mode (flycheck-select-checker 'proselint))
  )
(flycheck-define-checker proselint
  "A linter for prose."
  :command ("uvx" "proselint" "check" source-inplace)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ": "
            (id (one-or-more (not (any ":")))) ": "
            (message) line-end))
  :modes (org-mode
	  text-mode))

(add-to-list 'flycheck-checkers 'proselint)

;; Rust
(use-package rust-mode
  :ensure t
  :config
  (general-unbind 'normal rust-mode-map
  :with 'ignore
  [remap rust-test]
  [remap rust-check]
  [remap rust-run]))
;; Markdown
(use-package markdown-mode
  :ensure t)
;; Kdl
(use-package kdl-mode
  :ensure t
  :config
  (add-to-list 'treesit-language-source-alist
               '(kdl . ("https://github.com/tree-sitter-grammars/tree-sitter-kdl"
                        "master" "src"))))
;; Typescript
(add-to-list 'treesit-language-source-alist
               '(typescript . ("https://github.com/tree-sitter/tree-sitter-typescript"
                               "master" "typescript/src")))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))

;; Lua
(add-to-list 'treesit-language-source-alist
               '(lua . ("https://github.com/tree-sitter-grammars/tree-sitter-lua"
                        "main" "src")))
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-ts-mode))

;; Fish
(use-package fish-mode
  :ensure t)
(use-package fish-completion
  :ensure t)
;; Systemd Units
(use-package systemd
  :ensure t)

;; Treesitter

;; TODO replace X-mode to X-ts-mode

(defun ts/treesit-install-checked (out-dir)
  "Build and install the tree-sitter language grammar library
with `treesit-install-language-grammar' foreach LANG described
in `treesit-language-source-alist', skipping installation of a
LANG if `OUT-DIR/libtree-sitter-LANG.so' exsist."
  ;; Since shell commands called by `treesit-install-language-grammar' is
  ;; executed synchronously, a popup `*Messages*' buffer should make the
  ;; installation process less annoying.
  (init/show-msg)
  (message "Try install treesitter:")
  (dolist (recipe treesit-language-source-alist)
    (let* (
	   (lang (car recipe))
	   (so (format "libtree-sitter-%S.so" lang))
	   (lib (file-name-concat out-dir so))
	   )
      (if (file-exists-p lib)
	  (message "Treesitter for '%S' is available, skip" lang)
	(progn
	  (message "Building %s" so)
	  (treesit-install-language-grammar lang out-dir)
	  )
	)
      )))
(if (eq system-type 'gnu/linux)
  (ts/treesit-install-checked (init/expand-and-create "tree-sitter/"))
  )

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
  ((rust-mode python-mode c-mode c++-mode) . 'eglot-ensure)
  :config
  (normal-def
    :keymaps 'eglot-mode-map
    :state 'normal
    "<f2>" 'eglot-rename
    "C-." 'eglot-code-actions
    "K" nil ;; Overrride "K" -> `eldoc-doc-buffer'
    )
  (leader-def
    :keymaps 'eglot-mode-map
    :state 'normal
    "=" 'eglot-format
    "h h" 'eldoc-doc-buffer
    )
  (add-to-list
   'eglot-server-programs
   '((python-mode python-ts-mode) . ("uvx" "ty@0.0.51" "server"))
   )
  (add-to-list
   'eglot-server-programs
   '(rust-mode . ("rust-analyzer" :initializationOptions
		  (:cargo (:buildScripts (:enable t))))) ; cargo.buildScripts.enable = true
   ))

;; Syntax & spell check
(use-package flycheck
  :ensure t
  :custom
  (flycheck-auto-display-errors-after-checking nil)
  :config
  (setq flycheck-display-errors-function nil)
  :hook
  (prog-mode . flycheck-mode)
  )
(require 'flycheck-inline)
(global-flycheck-inline-mode)
(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :config
  (global-flycheck-eglot-mode 1))
(use-package jinx
  :ensure t
  :custom
  (jinx-languages "en")
  ;; :hook
  ;; (emacs-startup . global-jinx-mode)
  :config
  (defun jinx/correct-all-dwim (&optional _) (interactive)
    (unwind-protect
	(jinx-correct-all)
      (jinx-mode -1)))
  (leader-def
    "j" 'jinx/correct-all-dwim) ;; Disable jinx anyway
  (normal-def
    :keymaps 'jinx-mode-map
    "M-c" 'jinx-correct))
(defun jinx-next-pos (&optional n)
  "Return the position of Nth next misspelled word."
  (when jinx-mode
    (unless n (setq n 1))
    (unless (= n 0)
      (let ((ov (jinx--force-overlays (point-min) (point-max))))
	(unless (or (> n 0) (<= (overlay-start (car ov)) (point) (overlay-end (car ov))))
          (cl-incf n))
	(overlay-end (nth (mod n (length ov)) ov)) ;; return
	))))
(defun next-pos-in (pos-fn &optional n)
"Return the smallest position from the results of functions in POS-FN.
POS-FN is a list of symbols of functions with N as argument that return
a position or nil for unavailable.
If no positions exist, return nil."
(unless n
  (setq n 1))
(apply (if (> n 0)
	   'min 'max)
(cl-loop
 for fn in pos-fn
 for res = (funcall fn n)
 if res collect res)))
(defun next-error-dwim (&optional n)
  (interactive)
  (goto-char (next-pos-in '(jinx-next-pos flycheck-next-error-pos) n)))
(defun prev-error-dwim (&optional n)
  (interactive)
  (if n
      (next-error-dwim (- n))
    (next-error-dwim -1)))
(normal-def
  :keymaps 'flycheck-mode-map
  "<f11>" 'prev-error-dwim
  "<f12>" 'next-error-dwim)

;; Elisp
(add-hook 'emacs-lisp-mode-hook (lambda () (setq flycheck-emacs-lisp-load-path 'inherit)))

;; Snippet
(use-package yasnippet
  :ensure t)

;; Magit
(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :config
  (normal-def
    :keymaps 'magit-mode-map
    "h"  'magit-stash
    )
  (normal-def
    :keymaps 'magit-status-mode-map
    "M-j" 'magit-section-forward-sibling
    "M-k" 'magit-section-backward-sibling
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
(use-package helpful
  :ensure t
  :custom
  (helpful-max-buffers 1)
  (helpful-switch-buffer-function 'display-buffer)
  ;; (counsel-describe-function-function #'helpful-callable)
  ;; (counsel-describe-variable-function #'helpful-variable)
  :config
  (defun init/kill-extra-helpful-buffer (&rest _)
    "Kill extra `helpful' buffers and windows. Should invoke before `helpful--buffer'(See `advice-add')."
    (dolist (b (buffer-list))
      (when (eq (buffer-local-value 'major-mode b) 'helpful-mode)
	(delete-windows-on b)
	(kill-buffer b))))
  (advice-add 'helpful--buffer :before 'init/kill-extra-helpful-buffer)
  (leader-def
    :infix "h"
    "v" 'helpful-symbol
    "k" 'helpful-key)
  (leader-def
    :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map helpful-mode-map)
    :infix "h"
    "h" 'helpful-at-point))

;; Org
(use-package org
  :custom
  (org-return-follows-link t)
  (org-directory (init/expand-and-create "~/org/"))
  (org-startup-indented t)
  (org-preview-latex-default-process 'dvipng)
  (org-time-stamp-custom-formats ("%m/%d/%y W%u" . "%m/%d/%y W%u %H:%M"))
  (system-time-locale "en_US.UTF-8") ;; Display timestamp in the format like [2026-06-20 Sat 09:29]
  (org-startup-truncated nil) ;; Don't truncate lines
  (org-structure-template-alist '(("a" . "export ascii") ("c" . "center") ("C" . "COMMENT")
				  ("e" . "EXAMPLE") ("E" . "export") ("h" . "export html")
				  ("l" . "export latex") ("q" . "QUOTE") ("s" . "SRC") ("v" . "verse")))
  :hook
   (org-mode . (lambda () (display-line-numbers-mode -1)))
   (org-mode . yas-minor-mode)

  :config
  (defun org/meta-return-dwim (&optional arg)
    "Insert a new heading or wrap a region in a table.
Calls `org-insert-heading', `org-insert-item', 
`org-table-wrap-region' or `org-insert-todo-heading', depending on context.  When called with
an argument, unconditionally call `org-insert-heading'."
    (interactive "P")
    (or (run-hook-with-args-until-success 'org-metareturn-hook)
	(call-interactively (cond (arg #'org-insert-heading)
				  ((org-at-table-p) #'org-table-wrap-region)
				  ((or (org-at-item-checkbox-p)
				       (and (org-in-item-p)
					    (save-excursion
					      (previous-line)
					      (org-at-item-checkbox-p)))) #'org-insert-todo-heading)
				  ((org-in-item-p) #'org-insert-item)
				  (t #'org-insert-heading)))))
  
  (normal-def
    :keymaps 'org-mode-map
    "C-<left>" 'org-metaleft
    "C-<right>" 'org-metaright
    "C-<up>" 'org-metaup
    "C-<down>" 'org-metadown
    "C-," 'open-init-file
    )
  (general-def
    :keymaps 'org-mode-map
    :states 'insert
    "M--" (make-cmd #'yas-expand-snippet " -$0- ")
    "M-?" (make-cmd #'yas-expand-snippet " /$0/ ")
    "M-=" (make-cmd #'yas-expand-snippet " =$0= ")
    "M-*" (make-cmd #'yas-expand-snippet " *$0* ")
    "M-8" (make-cmd #'yas-expand-snippet " *$0* ")
    "M-)" (make-cmd #'yas-expand-snippet "\\\\($0\\\\)")
    "M-(" (make-cmd #'yas-expand-snippet "\\\\[\n$0\n\\\\]")
    "M-i" 'org-insert-structure-template
    "M-<return>" 'org/meta-return-dwim
    "M-S-<return>" 'org-meta-return
    )
  (general-def
    :keymaps 'org-mode-map
    :prefix "C-c"
    "C-l" 'org-insert-link
    )
  (normal-def
    :keymaps 'org-mode-map
    "t" 'org-toggle-checkbox)


  (defun org/do-subtree (func &optional up)
    "Loop over the current subtree.
This puts point at the start of the current subtree, and mark at
the end.  If a numeric prefix UP is given, move up into the
hierarchy of headlines by UP levels before marking the subtree."
    (interactive "P")
    (org-with-limited-levels
     (cond ((org-at-heading-p) (forward-line 0))
	   ((org-before-first-heading-p) (user-error "Not in a subtree"))
	   (t (outline-previous-visible-heading 1))))
    (when up (while (and (> up 0) (org-up-heading-safe)) (cl-decf up)))
    (if (called-interactively-p 'any)
	(call-interactively func)
      (apply func nil))))
(use-package org-agenda
  :after org
  :custom
  (org-agenda-files `(,(init/expand-and-create "~/org/agenda")))
  :config
  (defun org-agenda-next-header ()
    "Jump to the next header in an agenda series."
    (interactive)
    (-org-agenda-goto-header))

  (defun org-agenda-previous-header ()
    "Jump to the previous header in an agenda series."
    (interactive)
    (-org-agenda-goto-header t))

  (defun -org-agenda-goto-header (&optional backwards)
    "Find the next agenda series header forwards or BACKWARDS."
    (let ((pos (save-excursion
		 (goto-char (if backwards
				(line-beginning-position)
                              (line-end-position)))
		 (let* ((find-func (if backwards
                                       'previous-single-property-change
                                     'next-single-property-change))
			(end-func (if backwards
                                      'max
                                    'min))
			(all-pos-raw (list (funcall find-func (point) 'org-agenda-structural-header)
                                           ;; (funcall find-func (point) 'org-agenda-date-header)
					   ))
			(all-pos (cl-remove-if-not 'numberp all-pos-raw))
			(prop-pos (if all-pos (apply end-func all-pos) nil)))
                   prop-pos))))
      (if pos (goto-char pos))
      (if backwards (goto-char (line-beginning-position)))))
  (defun org/timestamp-smart (&optional arg)
    (interactive)
    (let (
	  (old (point))
	  (new (progn
		 (org-timestamp nil nil)
		 (point)))
	  )
      (unless (eq (char-before old) ? )
	(goto-char old)
	(insert ? ))
      (goto-char new)
      )
    )
  (defun org/clock-in-dwim (&optional arg)
    "With a `\\[universal-argument]' prefix argument ARG, do as `org-clock-in' do in case of no `\\[universal-argument]'"
    (interactive "P")
    (cond
     ((equal arg nil) ;; With no `\\[universal-argument]' prefix argument ARG
      (org-clock-in)) 
     ((equal arg '(4)) ;; With a `\\[universal-argument]' prefix argument ARG
      (org-clock-in nil (org-read-date :inactive t)))
     ))

  (general-def
    :keymaps 'org-agenda-mode-map
    "z" nil
    "s" (lambda () (org-save-all-org-buffers) (org-agenda-redo-all))
    "J" 'org-agenda-next-header
    "K" 'org-agenda-previous-header
    "j" 'org-agenda-next-item
    "k" 'org-agenda-previous-item)
  (general-def
    :keymaps 'org-agenda-mode-map
    :prefix "z"
    "q" 'kill-unimportant-buffer-and-windows
    "k" 'delete-window
    "K" 'kill-buffer-and-window
    "1" 'delete-other-windows
    "2" 'split-window-below
    "3" 'split-window-right
    "z" 'w/smart-other-window

    "o" 'other-window-prefix
    "b" 'switch-to-buffer-other-window
    "d" 'dired-other-window
    "f" 'find-file-other-window)
  (general-def
    :keymaps 'override
    "M-<SPC>" #'org-agenda)
  (normal-def
    :keymaps 'org-mode-map
    "M-t" 'org-todo
    "M-p" 'org-priority-down
    )
  (normal-def
    :infix "C-c"
    :keymaps 'org-mode-map
    :states '(normal insert)
    "<up>" (defrepeater 'org-timestamp-up)
    "<down>" (defrepeater 'org-timestamp-down)
    "e" 'org-export-dispatch
    "C-s" 'org-schedule
    "C-d" 'org-deadline
    "C-t" 'org/timestamp-smart
    "C-o" 'org-clock-out
    "C-i" 'org-clock-in
    "C-q" 'org-clock-cancel
    "i" 'org-clock-in-last
    "o" 'org-clock-report)
  (defun org/skip-subtree-if-priority (priority)
    "Skip an agenda subtree if it has a priority of PRIORITY.

PRIORITY may be one of the characters `?A', `?B' or `?C'.

The default “lowest priority” value is 67, and the ASCII value of “A” is 65, so the numeric value of priority “A” is 2,000, “B” (ASCII value 66) is 1,000, and “C” (ASCII value 67) is 0."
    (let ((subtree-end (save-excursion (org-end-of-subtree t)))
          (pri-value (* 1000 (- org-lowest-priority priority)))
          (pri-current (org-get-priority (thing-at-point 'line t))))
      (if (= pri-value pri-current)
          subtree-end
	nil)))
  (defun org/skip-file (files)
    (cl-loop
     for file in files
     if (file-equal-p (buffer-file-name) file)
     return (point-max)))
  (defvar long-term-file "~/org/agenda/long-term.org")
  (defvar appointment-file "~/org/agenda/appointment.org")
  (defvar task-file "~/org/agenda/task.org")
  (org-add-agenda-custom-command
   '(" " "Task view"
     ((tags "PRIORITY=\"A\""
	    ((org-agenda-files `(,task-file))
	     (org-agenda-skip-function
		   '(org-agenda-skip-entry-if 'todo 'done))
             (org-agenda-overriding-header "#A TODOs:")
	     (org-agenda-prefix-format "  ")))
      (agenda ""
	    ((org-agenda-files `(,task-file))))
      (alltodo ""
	       ((org-agenda-files `(,task-file))
		(org-agenda-skip-function 
		 '(or 
		   ;; Filter TODOs with a priority of `?A', a SCHEDULED or a DEADLINE
		   (org/skip-subtree-if-priority ?A)
		   ;; `nil' means only the entry (i.e. the text before the next heading) is checked
		   (org-agenda-skip-if nil '(scheduled deadline))
		   ))
		(org-agenda-prefix-format " ")
		)))))
  (org-add-agenda-custom-command
   '("l" "Long term agenda view"
     (
      (agenda* ""
	       ((org-agenda-files `(,long-term-file))))
      (alltodo ""
	       ((org-agenda-files `(,long-term-file))
		(org-agenda-prefix-format " ")
		(org-agenda-sorting-strategy '(priority-down)))
	       ))))
  (setq org-clock-persist t
	org-clock-idle-time 10) ;; minutes
  (org-clock-persistence-insinuate)
  )
(use-package org-roam
  :ensure t
  :after org
  :init
  (setq org-roam-v2-ack t) ;; Acknowledge V2 upgrade
  (setq org-roam-directory org-directory)
  (init/expand-and-create "dailies/" org-roam-directory)
  (setq org-roam-dailies-directory "dailies/") ;; Relative path is required
  :config
  (org-roam-db-autosync-mode)
  (leader-def
    :keymaps 'org-mode-map
    :infix "o"
    "i" 'org-roam-node-insert
    ;; "o" 'org-id-get-create
    "t" 'org-roam-tag-add
    "l" 'org-roam-buffer-toggle
    ;; "a" 'org-roam-alias-add
    )
  (general-def
    :keymaps 'org-capture-mode-map
    "C-c C-f" 'org-capture-finalize)
  :custom
  (org-roam-capture-templates
	'(("d" "default" plain "%?"
           :target (file+head "${slug}.org"
                              "#+title: ${title}
")
           :unnarrowed t)

	  ))
  )
(use-package xenops
  :ensure t
  :after org
  :hook
  ((latex-mode org-mode) . xenops-mode)
  :config
  ;; (add-hook 'org-mode-hook 'xenops-mode 100)
  ;; (add-hook 'Latex-mode-hook 'xenops-mode 100)
  (setq xenops-reveal-on-entry t)
  (setq xenops-math-image-scale-factor 0.6)
  (setq xenops-image-directory (init/expand-and-create "~/org/attachments/"))
  ;; (advice-add 'xenops-dwim :before (lambda (&rest _)
  ;; 				     (unless xenops-mode (xenops-mode))))
  (leader-def
    :keymap '(org-mode-map latex-mode-map)
    "x" 'xenops-mode
    "p" 'xenops-image-handle-paste)
  (defun xenops-image-write-clipboard-image-to-file--wl-paste (temp-file)
    "Handle paste event using wl-paste(Linux/Wayland)."

    (when (executable-find "wl-paste")
      (let ((exit-status
             (call-process "wl-paste" nil `(:file ,temp-file) nil "-t" "image/png")))
	(= exit-status 0))))
  (if (getenv "WAYLAND_DISPLAY")
      (advice-add 'xenops-image-write-clipboard-image-to-file--xclip
		  :before-until 'xenops-image-write-clipboard-image-to-file--wl-paste))
  ;; Try wl-paste first in case of Xwayland mess up xclip

  (defun xenops-src-parse-at-point-a ()
	      (if-let* ((element (xenops-parse-element-at-point 'src))
			(org-babel-info
			 (xenops-src-do-in-org-mode
			  (org-babel-get-src-block-info 'light (org-element-context)))))
		  (xenops-util-plist-update
		   element
		   :type 'src
		   :language (nth 0 org-babel-info)
		   :org-babel-info org-babel-info)))
  (advice-add 'xenops-src-parse-at-point :override #'xenops-src-parse-at-point-a)
  )
(use-package org-appear
  :ensure t
  :after org
  :custom
  (org-hide-emphasis-markers t)
  (org-appear-trigger 'always)
  :init
  ;; inline mark of Chinese 
  (defvar org-hide-space-keywords
    '(("\\cc\\( \\)[*/_=~+]\\cc.*?[*/_=~+]"
       (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))
      ("[*/_=~+].*?\\cc[*/_=~+]\\( \\)\\cc"
       (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))))
  (font-lock-add-keywords 'org-mode org-hide-space-keywords 'append)
  ;; hack `org-appear--show-invisible' to hide spaces wrapping the non-ASCLL characters.
  (defun o/org-appear--show-invisible (elem)
    "Silently remove invisible property from invisible parts of element ELEM."
    (let* ((elem-at-point (org-appear--parse-elem elem))
	   (elem-type (car elem))
	   (start (plist-get elem-at-point :start))
	   (end (plist-get elem-at-point :end))
	   (visible-start (plist-get elem-at-point :visible-start))
	   (visible-end (plist-get elem-at-point :visible-end)))
      (when (and (eq org-appear-autolinks 'just-brackets)
		 (eq elem-type 'link))
	(setq start (1- visible-start))
	(setq end (1+ visible-end)))
      (with-silent-modifications
	(cond ((eq elem-type 'entity)
	       (decompose-region start end))
	      ((memq elem-type '(latex-fragment latex-environment))
	       (when org-appear-autosubmarkers
		 (remove-text-properties start end '(invisible)))
	       (when org-appear-autoentities
		 (decompose-region start end)))
	      ((eq elem-type 'keyword)
	       (remove-text-properties start end '(invisible org-link)))
	      ((and (featurep 'org-fold)
		    (eq elem-type 'link)
		    (eq org-fold-core-style 'text-properties))
	       (remove-text-properties start
				       visible-start
				       (list (org-fold-core--property-symbol-get-create 'org-link) nil))
	       (remove-text-properties visible-end
				       end
				       (list (org-fold-core--property-symbol-get-create 'org-link) nil)))
	      (t
	       ;; (remove-text-properties start visible-start '(invisible org-link))
	       (remove-text-properties (1- start) visible-start '(invisible org-link))
	       ;; (remove-text-properties visible-end end '(invisible org-link))
	       (remove-text-properties visible-end (1+ end) '(invisible org-link))
	       )))))
  (advice-add 'org-appear--show-invisible :override 'o/org-appear--show-invisible)
  ;; evil integration
  ;; (setq org-appear-trigger 'manual)
  ;; (add-hook 'org-mode-hook 'org-appear-mode)
  ;; (add-hook 'org-mode-hook (lambda ()
  ;;                            (add-hook 'evil-insert-state-entry-hook
  ;;                                      #'org-appear-manual-start
  ;;                                      nil
  ;;                                      t)
  ;;                            (add-hook 'evil-insert-state-exit-hook
  ;;                                      #'org-appear-manual-stop
  ;;                                      nil
  ;;                                      t)))
  )
;; Provides visual alignment for Org Mode, Markdown and table.el tables
(use-package valign
  :ensure t
  :hook
  ((markdown-mode org-mode) . valign-mode))

;; Shell & Terminal & Complication
(use-package shell
  :custom
  (explicit-shell-file-name "/usr/bin/fish")
  (shell-file-name "/usr/bin/fish"))
(use-package compile
  :custom
  (compilation-auto-jump-to-first-error t)
  :general
  (:keymaps 'override
	    :states 'normal
   "SPC c" 'compile)
  (:keymaps 'compilation-mode-map
	    "j" 'compilation-next-error
	    "k" 'compilation-previous-error)
  :config
  (defun cmpi/finish-focus-comp (&optional buf-or-proc arg2)
    (let* ((comp-buf (if (processp buf-or-proc)
                         (process-buffer buf-or-proc)
                       buf-or-proc))
           (window (get-buffer-window comp-buf)))
      (if window
          (select-window window)
        (switch-to-buffer-other-window comp-buf))))
  (add-hook 'compilation-finish-functions 'cmpi/finish-focus-comp)
  (add-hook 'compilation-start-functions 'cmpi/finish-focus-comp)
  )
(use-package fancy-compilation
  :ensure t
  :after compile
  :custom
  (fancy-compilation-override-colors nil)
  :config
  (fancy-compilation-mode))

;; Web Browser
(setq browse-url-browser-function 'browse-url-firefox)
(setq browse-url-firefox-program "zen")

;; IM
(use-package sis
  :ensure t
  :hook
  enable the /context/ and /inline region/ mode for specific buffers
  ((text-mode prog-mode) . sis-context-mode)
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
  (sis-global-inline-mode nil)
  (setq sis-inline-with-english nil)
  (add-to-list 'sis-respect-minibuffer-triggers
               (cons 'gptel--suffix-send (lambda () 'other))
	       )
  )

;; AI
(defun process-to-string (programme &rest args)
  "Call PROGRAMME with ARGS via `call-process', return `(exit-code . stdout)'."
  (with-temp-buffer
    `(
     ,(apply #'call-process programme nil t nil args) ;; exit-code
     .
     ,(buffer-string)				      ;; stdout
    )
    ))
(defun ai/get-key ()
  (let* (
	 (val (process-to-string "rbw" "get" "deepseek-api"))
	 (code (car val))
	 (key (cdr val))
	 )
	(if (eq code 0)
	    key
	  (error (concat "Failed to get api-key: " key)))))
(use-package gptel
  :ensure t
  :custom
  (evil-collection-gptel-want-ret-to-send nil)
  (gptel-model 'deepseek-v4-flash)
  (gptel-backend (gptel-make-openai "DS"
		   :protocol "https"
		   :host "api.deepseek.com"
		   :endpoint "/chat/completions"
		   :stream t
		   :key #'ai/get-key
		   :models '(deepseek-v4-flash deepseek-v4-pro)
		   ))
  (gptel-org-convert-response nil)
  :general
  (:keymaps 'override
	    "C-c RET" 'gptel-menu
	    "C-c C-a" 'gptel-abort
	    "S-<return>" 'gptel-send
	    )
  :config
  (gptel-make-preset 'default
    :description nil :backend "DS" :model 'deepseek-v4-flash :system
    'default :tools 'nil :stream t :temperature 1.0 :max-tokens nil
    :use-context 'nil :track-media nil :include-reasoning t)
  (gptel-make-preset 'quick
    :description nil :backend "DS" :model 'deepseek-v4-flash :system
    "Respond in one line if possible" :tools 'nil :stream t :temperature 1.0 :max-tokens nil
    :use-context 'nil :track-media nil :include-reasoning nil)
  (defun md->org-from-kill-ring (&optional arg)
    (interactive)
    (insert (gptel--convert-markdown->org (current-kill 0))))
  (remove-hook 'gptel-post-response-functions 'pulse-momentary-highlight-region) ;; Disable the blink after response
  )

;; Dict
(use-package quick-sdcv
  :ensure t
  :if (executable-find "sdcv")
  :custom
  (quick-sdcv-dictionary-prefix-symbol "►")
  (quick-sdcv-ellipsis " ▼")
  :config
  (normal-def
    :keymaps 'quick-sdcv-mode-map
    "q" 'kill-buffer-and-window)
  (leader-def
    "d" 'quick-sdcv-search-input))

;; Folding
(use-package kirigami
  :ensure t
  :config
  (normal-def
    "\\" 'kirigami-toggle-fold
    "|" 'kirigami-close-folds))

;; Leetcode
(use-package leetcode
  :ensure t
  :hook
  (leetcode--problem-detail . (lambda () (display-line-numbers-mode -1)))
  :config
  (init/expand-and-create "leetcode-env/"))

;; Pdf
(defvar pdf/scroll-offset 10)
(defvar pdf/scroll-big-offset (* pdf/scroll-offset 5))

(use-package pdf-tools
  :ensure t
  :custom
  (pdf-info-epdfinfo-program (expand-file-name "pdf-tools/server/epdfinfo"))
  :hook
  ((pdf-view-mode . (lambda () (display-line-numbers-mode -1)))
   (pdf-view-mode . (lambda () (centered-cursor-mode -1)))
   )
  :general
  (:keymaps 'pdf-view-mode-map
	    :states 'normal
	    "j" (make-cmd #'pdf-view-next-line-or-next-page pdf/scroll-offset)
	    "J" (make-cmd #'pdf-view-next-line-or-next-page pdf/scroll-big-offset)
	    "k" (make-cmd #'pdf-view-previous-line-or-previous-page pdf/scroll-offset)
	    "K" (make-cmd #'pdf-view-previous-line-or-previous-page pdf/scroll-big-offset)
	    "M-[" #'pdf-view-previous-page
	    "M-]" #'pdf-view-next-page)
  :config
  (pdf-tools-install))

(provide 'init)
;;; init.el ends here

