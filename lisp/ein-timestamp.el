;;; ein-timestamp.el --- Elisp implementation of the ExecuteTime nbextension

;; Copyright (C) 2018- John M. Miller

;; Author: John M. Miller <millejoh at mac.com>

;; This file is NOT part of GNU Emacs.

;; ein-timestamp.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ein-timestamp.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ein-kernel.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A rough approximation of the ExecuteTime (https://jupyter-contrib-nbextensions.readthedocs.io/en/latest/nbextensions/execute_time/readme.html) nbextension

;;; Code:

(require 'ein-kernel)
(require 'ein-cell)

(defun ein:timestamp--shell-reply-hook (msg-type header content metadata)
  (when (string-equal msg-type "execute_reply")
    (let ((start-time (plist-get metadata :started))
          (end-time (plist-get header :date)))
      (plist-put metadata :execute-time (cons start-time end-time)))))

(defun ein:timestamp--execute-reply-hook (cell content metadata)
  (if-let ((etime (plist-get metadata :execute-time)))
      (if (ein:cell-metadata cell)
          (plist-put (ein:cell-metadata cell)
                     :execute-time
                     etime)
        (setf (ein:cell-metadata cell) (list :execute-time etime))))
  (ein:cell-running-set cell nil)
  (ewoc-invalidate (ein:basecell--ewoc cell) (ein:cell-element-get cell :footer)))

(defmethod ein:cell-insert-footer :after ((cell ein:codecell))
  (if (slot-value cell 'running)
      (ein:insert-read-only "Execution pending\n\n")
    (if-let ((etime (plist-get (ein:cell-metadata cell) :execute-time)))
        (let ((start-time (date-to-time (car etime)))
              (end-time (date-to-time (cdr etime))))
          (ein:insert-read-only (format "Last executed %s in %ss\n\n"
                                        (current-time-string start-time)
                                        (float-time (time-subtract end-time start-time))))))))

(add-hook 'ein:on-shell-reply-functions 'ein:timestamp--shell-reply-hook)
(add-hook 'ein:on-execute-reply-functions 'ein:timestamp--execute-reply-hook)

(provide 'ein-timestamp)
