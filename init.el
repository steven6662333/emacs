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
  '("*Help*" "*helpful"  "*Warning*" "*Messages*" "*Backtrace*" "*complication*" "\*eldoc" "*sdcv*")
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
(when (display-graphic-p) (scroll-bar-mode -1)) ; 图形界面时关闭滚动条
(setq split-width-threshold 0)  ; 始终优先垂直分割（宽度阈值设为 0）
(setq split-height-threshold nil) ; 禁用水平分割的高度阈值
(setq server-client-instructions nil)
(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 90))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 75)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）

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

(add-hook 'after-make-frame-functions 'init/setfont 100)

(init/setfont)

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
(defmacro make-cmd (func &rest args)
  "Create an interactive command that calls FUNC with ARGS.
FUNC must be provided with #' syntax.
Usage: (global-set-key (kbd \"M-*\") 
                       (make-interactive-command #'yas-expand-snippet \"* $0 *\"))"
  `(lambda ()
     (interactive)
     (,(cadr func) ,@args)))

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
(use-package key-chord ;; "jj" for exit
  :ensure t
  :after evil
  :config
  (setq key-chord-two-keys-delay 0.3)
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state))
(use-package defrepeater
  :ensure t)

;; Core kbds

(general-create-definer leader-def
  :states '(normal motion)
  :keymaps 'override
  :prefix "SPC")
(general-create-definer normal-def
  :states '(normal motion))
(general-create-definer win-def :keymaps 'override :prefix "C-w")

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
  "/" 'evil-ex-nohighlight)

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

(normal-def
  :keymaps 'prog-mode-map
  "C-/" 'comment-dwim
  "M-/" 'comment-line
  "C-e" 'eval-last-sexp)

;; Better `find-file'
(defadvice find-file (before make-directory-maybe (filename &optional wildcards) activate)
  "Create parent directory if not exists while visiting file."
  (unless (file-exists-p filename)
    (let ((dir (file-name-directory filename)))
      (unless (file-exists-p dir)
        (if (yes-or-no-p "Create parent directory?") (make-directory dir t))))))

(leader-def
  "s" 'server-edit
  "S" '(lambda () (interactive) (jinx-mode 'toggle))
  "b" 'switch-to-buffer
  "SPC" (lambda () (interactive) (dired "."))
  "r" 'recentf
  "f" 'find-file
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
  ;; Fix `evil-search-next'
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
    "Add latest `consult-line' search pattern to the evil search history ring."
    (when consult--line-history
                (add-to-history
                 'regexp-search-ring ;; or search-ring
                 (car consult--line-history)
                 regexp-search-ring-max)))
  (advice-add #'consult-line :after #'noct-consult-line-evil-history)
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
  :ensure t)
;; Fish
(use-package fish-mode
  :ensure t)
(use-package fish-completion
  :ensure t)
;; Systemd Units
(use-package systemd
  :ensure t)


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
  (append
   '(python-mode . ("uvx" "ty" "server"))
   '(rust-mode . ("rust-analyzer" :initializationOptions
		  (:cargo (:buildScripts (:enable t))))) ; cargo.buildScripts.enable = true
   'eglot-server-programs
   ))

;; Syntax & spell check
(use-package flycheck
  :ensure t
  :config
  (normal-def
    :keymaps 'flycheck-mode-map
    "<f8>" 'flycheck-next-error
    "S-<f8>" 'flycheck-previous-error
    )
  :hook (prog-mode-hook . flycheck-mode))
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
  :general
  (:keymaps 'override
	    "M-$" 'jinx-correct
            "C-M-$" 'jinx-languages))

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
  :hook
  (org-mode-hock . (make-cmd #'toggle-truncate-lines nil)) ;; Don't truncate lines
  :config
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
    "M-/" (make-cmd #'yas-expand-snippet " /$0/ ")
    "M-=" (make-cmd #'yas-expand-snippet " =$0= ")
    "M-*" (make-cmd #'yas-expand-snippet " *$0* ")
    "M-8" (make-cmd #'yas-expand-snippet " *$0* ")

    "M-t" 'org-insert-todo-heading
    )
  )
(use-package org-agenda
  :after org
  :custom
  (org-agenda-files `(,(init/expand-and-create "~/org/agenda")))
  :config
  (normal-def
    :keymaps 'override
    "M-<SPC>" (make-cmd #'org-agenda nil "c"))
  (normal-def
    :keymaps 'org-mode-map
    "M-t" 'org-todo
    )
  (normal-def
    :infix "C-c"
    :keymaps 'org-mode-map
    "<up>" (defrepeater 'org-timestamp-up)
    "<down>" (defrepeater 'org-timestamp-down)
    "e" 'org-export-dispatch)
  (org-add-agenda-custom-command
   '("c" "Custom agenda view" agenda ""))
  )
(use-package org-roam
  :ensure t
  :after org
  :init
  (setq org-roam-v2-ack t) ;; Acknowledge V2 upgrade
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
  :custom
  (org-roam-directory (concat org-directory "roam/"))
  (org-roam-dailies-directory "dailies/")
  (org-roam-capture-templates
	'(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}
#+STARTUP: latexpreview\n")
           :unnarrowed t)

	  ))
  )
(use-package xenops
  :ensure t
  :after org
  :custom
  (xenops-reveal-on-entry t)
  :hook
  ((latex-mode org-mode-hook) . xenops-mode)
  :config
  (leader-def
    :keymap '(org-mode-map latex-mode-map)
    "x" 'xenops-dwim))
(use-package org-appear
  :ensure t
  :after org
  :custom
  (org-hide-emphasis-markers t)
  :init
  ;; inline mark of Chinese 
  (defvar org-hide-space-keywords
    '(("\\cc\\( \\)[*/_=~+]\\cc.*?[*/_=~+]"
       (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))
      ("[*/_=~+].*?\\cc[*/_=~+]\\( \\)\\cc"
       (0 (prog1 () (when org-hide-emphasis-markers (add-text-properties (match-beginning 1) (match-end 1) '(invisible t))))))))
  (font-lock-add-keywords 'org-mode org-hide-space-keywords 'append)
  ;; hack `org-appear--show-invisible'
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
  (setq org-appear-trigger 'manual)
  (add-hook 'org-mode-hook 'org-appear-mode)
  (add-hook 'org-mode-hook (lambda ()
                             (add-hook 'evil-insert-state-entry-hook
                                       #'org-appear-manual-start
                                       nil
                                       t)
                             (add-hook 'evil-insert-state-exit-hook
                                       #'org-appear-manual-stop
                                       nil
                                       t)))

  )
;; Provides visual alignment for Org Mode, Markdown and table.el tables
(use-package valign
  :ensure t
  :hook
  (org-mode-hook . valign-mode))

;; Shell & Terminal & Complication
(use-package shell
  :custom
  (explicit-shell-file-name "/usr/bin/fish")
  (shell-file-name "/usr/bin/fish"))
(use-package compile
  :custom
  (compilation-auto-jump-to-first-error t)
  :general
  ("C-c C-c" 'compile)
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
    "d" 'quick-sdcv-search-at-point
    "h d" 'quick-sdcv-search-input))

;; Folding
(use-package kirigami
  :ensure t
  :config
  (normal-def
    "\\" 'kirigami-toggle-fold
    "|" 'kirigami-close-folds))

(provide 'init)
;;; init.el ends here

