(set-terminal-parameter nil 'xterm--set-selection t)

(xterm-mouse-mode 1)
(mouse-wheel-mode 1)

(global-set-key (kbd "<mouse-4>") #'scroll-down-line)
(global-set-key (kbd "<mouse-5>") #'scroll-up-line)
(global-set-key (kbd "<wheel-up>") #'scroll-down-line)
(global-set-key (kbd "<wheel-down>") #'scroll-up-line)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(cua-mode t)
 '(frame-background-mode 'light)
 '(save-place-mode t)
 '(size-indication-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
