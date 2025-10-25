;;; init.el --- Terminal Emacs config for Python development
;;; Written for terminal-only Emacs, Emacs 27+

;; ---------------------------
;; Package setup
;; ---------------------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(setq package-enable-at-startup nil)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t)

;; ---------------------------
;; Basic UI / terminal settings
;; ---------------------------
;; don't load GUI-only stuff
(setq inhibit-startup-screen t
      inhibit-startup-message t
      visible-bell t)

;; no toolbar/menu/scrollbar (safe in terminal)
(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; UTF-8
(prefer-coding-system 'utf-8)

;; Line numbers: relative in programming modes, absolute in other buffers
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative) ; use 'relative for programming
;; Disable line numbers in certain modes where it looks bad
(dolist (mode '(org-mode-hook
                term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                treemacs-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Shorter prompts
(fset 'yes-or-no-p 'y-or-n-p)

;; ---------------------------
;; Basic editing niceties
;; ---------------------------
(setq-default indent-tabs-mode nil) ; use spaces
(setq-default tab-width 4)
(setq-default python-indent-offset 4)
(electric-pair-mode 1)
(show-paren-mode 1)
(global-auto-revert-mode 1)
(setq make-backup-files nil) ; disable ~ backups
(setq auto-save-default nil)

;; ---------------------------
;; Keybindings
;; ---------------------------
;; Use C-c C-l to reload init
(global-set-key (kbd "C-c C-l") #'(lambda () (interactive) (load-file user-init-file)))

;; Quick terminal-friendly window movement
(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

;; ---------------------------
;; Which-key
;; ---------------------------
(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.6))

;; ---------------------------
;; Better minibuffer completion
;; ---------------------------
(use-package vertico
  :init
  (vertico-mode))
(use-package consult)
(use-package marginalia
  :after vertico
  :config
  (marginalia-mode))

;; ---------------------------
;; Project management
;; ---------------------------
(use-package project
  :ensure nil ; built-in
  :bind-keymap
  ("C-c p" . project-prefix-map))

;; ---------------------------
;; Undo/redo
;; ---------------------------
(use-package undo-fu
  :bind (("C-/" . undo-fu-only-undo)
         ("C-?" . undo-fu-only-redo)))

;; ---------------------------
;; LSP and Python support
;; ---------------------------
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook ((python-mode . lsp-deferred))
  :init
  (setq lsp-keymap-prefix "C-c l")  ;; prefix for lsp-command-keymap
  :config
  (setq lsp-enable-snippet nil) ;; disable snippets if you prefer
  (setq lsp-prefer-capf t)      ;; use completion-at-point
  (setq lsp-log-io nil)
  (setq lsp-idle-delay 0.500))

(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-code-actions t
        lsp-ui-doc-enable nil)) ;; disable pop-up doc in terminal

(use-package lsp-pyright
  :after (lsp-mode python-mode)
  :custom
  (lsp-pyright-auto-import-completions t)
  (lsp-pyright-typechecking-mode "basic")
  :hook (python-mode . (lambda ()
                         (require 'lsp-pyright)
                         (lsp-deferred))))

;; ---------------------------
;; Autocompletion (company + yasnippet)
;; ---------------------------
(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-tooltip-align-annotations t)
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.08)
  :bind
  (:map company-active-map
        ("<tab>" . company-complete-common-or-cycle)
        ("TAB" . company-complete-common-or-cycle))
  :config
  ;; Integrate with lsp
  (setq company-backends '((company-capf company-files))))

(use-package yasnippet
  :init
  (yas-global-mode 1))

;; ---------------------------
;; Keybindings for common LSP actions
;; ---------------------------
;; These are terminal-friendly and added globally for programming modes
(defun my/python-lsp-keys ()
  (local-set-key (kbd "M-.") #'lsp-find-definition)      ; go to definition
  (local-set-key (kbd "M-,") #'lsp-find-references)      ; find refs
  (local-set-key (kbd "C-c r") #'lsp-rename)             ; rename
  (local-set-key (kbd "C-c a") #'lsp-execute-code-action)); code actions

(add-hook 'python-mode-hook #'my/python-lsp-keys)

;; ---------------------------
;; Python mode improvements
;; ---------------------------
(use-package python
  :ensure nil
  :hook ((python-mode . (lambda ()
                          (setq-local tab-width 4)
                          (setq-local python-indent-offset 4)))))

(use-package pyvenv
  :config
  ;; Try to activate venv if PYENV/VIRTUAL_ENV present
  (when (getenv "VIRTUAL_ENV")
    (pyvenv-activate (getenv "VIRTUAL_ENV"))))

;; ---------------------------
;; Formatting & linting
;; ---------------------------
(use-package blacken
  :hook (python-mode . blacken-mode)
  :custom
  (blacken-line-length 88))

(use-package flycheck
  :init (global-flycheck-mode))

;; Configure flycheck to use lsp diagnostics primarily
(with-eval-after-load 'lsp-mode
  (setq lsp-diagnostic-package :none)) ; rely on flycheck + lsp-ui-sideline

;; ---------------------------
;; Navigation: find-file, projectile optional
;; ---------------------------
(use-package projectile
  :diminish projectile-mode
  :config
  (projectile-mode +1)
  :custom
  (projectile-project-search-path '("~/projects/" "~/src/")))

;; ---------------------------
;; Terminal integration (optional)
;; ---------------------------
(use-package vterm
  :if (executable-find "bash") ; only if compiled with libvterm
  :commands vterm
  :config
  (setq vterm-shell (or (getenv "SHELL") "/bin/bash")))

;; ---------------------------
;; File associations and modes
;; ---------------------------
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(add-to-list 'auto-mode-alist '("Pipfile\\'" . toml-mode))

;; ---------------------------
;; Performance tweaks
;; ---------------------------
(setq gc-cons-threshold 100000000) ;; 100MB
(setq read-process-output-max (* 1024 1024)) ;; 1MB for LSP

;; ---------------------------
;; Helper: install external language servers
;; ---------------------------
;; For Python, install pyright: `npm i -g pyright` or `npm i -g pyright@latest`
;; This config expects pyright in PATH. Alternatively, use 'python-language-server'.

;; ---------------------------
;; Final
;; ---------------------------
(message "Emacs config loaded: terminal Python setup with LSP and company")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
