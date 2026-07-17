;; mjr-vergo --- Provide verGo.sh in Emacs. -*-coding: utf-8 lexical-binding:t mode:emacs-lisp -*-

;; Copyright (C) 2026-2026 First Last me@mitchr.me

;; Author:      Mitch Richling <https://github.com/richmit/verGo>
;; Created:     2026-07-17
;; Version:     0.2
;; Keywords:    verGo
;; URL:         https://github.com/richmit/verGo

;; This file is not part of Emacs

;;; Install:

;; Manual: Put mjr-vergo.el on your `load-path' and add to your ~/.emacs startup file:
;;      (require 'mjr-vergo)
;; As a package:
;;      (package-vc-install (list 'mjr-vergo
;;                                :url "https://github.com/richmit/verGo"
;;                                :lisp-dir "emacs-lisp"
;;                                :main-file "mjr-vergo.el"
;;                                :rev 'newest))

;;; Commentary:

;; Provide access to verGo.sh from inside Emacs.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defgroup mjr-vergo nil
  "Access verGo.sh from emacs.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-vergo-bin (locate-file "verGo.sh" exec-path)
  "File to use for vreGo.sh"
  :type 'file
  :group 'mjr-vergo)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-vergo (app &optional path-format)
  "Use verGo.sh to find a binary and any environment variables  that need to be set (returned as a list of strings).
If path-format is invalid or missing, then `MIX' is used.  NIL is returned if anything goes wrong -- no errors are raised."
  (when-let* ((path-format (or (car (member path-format '(RAW UNIX WIN DOS MIX)))
                               'MIX))
              (ver-go-bin  mjr-vergo-bin)
              (            (file-exists-p ver-go-bin))
              (            (stringp app))
              (            (not (string-empty-p app)))
              (cmd         (concat ver-go-bin " -noErrors -noRun -prtCmd -prtVar -prtFmt " (upcase (symbol-name path-format)) " -app " app))
              (res-raw     (shell-command-to-string cmd))
              (res-trm     (string-trim res-raw))
              (ret         (split-string res-trm "\n"))
              (            (listp ret))
              (exe-path    (car ret))
              (            (stringp exe-path))
              (            (not (string-empty-p exe-path)))
              (            (or (and (eq system-type 'windows-nt) (or (eq path-format 'RAW) (eq path-format 'UNX))) 
                               (file-executable-p exe-path))))
    ret))

(provide 'mjr-vergo)

 
;;(load-library "~/.emacs.d/mjr-vergo.el")

;;(mjr-vergo "octave")
;;(require 'mjr-vergo)

;;(push "c:/msys64/home/richmit/.emacs.d/" load-path)



;;(package-vc-install-from-checkout

