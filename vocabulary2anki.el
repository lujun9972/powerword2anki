#!/bin/sh
":"; exec emacs --quick --script "$0" -- "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-

(defun v2a-read-vocabulary (&optional pos buffer)
  "读入一个生词,返回一个(单词 释义 音标)的list

POS参数指定了从那个位置开始读取,默认为当前位置.
BUFFER参数指定了从哪个buffer中读取"
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (if pos
          (goto-char pos))
      (let ((spell (v2a-read-spell nil buffer))
            (meaning (v2a-read-meaning nil buffer))
            (phonetic (v2a-read-phonetic nil buffer)))
        (list spell meaning phonetic)))))
;; (v2a-read-vocabulary nil "默认生词本.txt")

(defun v2a--read-content-between (start-tag end-tag &optional pos buffer)
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (if pos
          (goto-char pos))
      (let ((start-pos (progn (search-forward-regexp (format "^%s" (regexp-quote start-tag)))
                              (point)))
            (end-pos (progn (search-forward-regexp (format "^%s" (regexp-quote end-tag)))
                            (backward-char (length end-tag))
                            (point))))
        (string-trim (buffer-substring-no-properties start-pos end-pos))))))

;; (v2a--read-content-between "+" "#" 0 "默认生词本.txt")

(defun v2a-read-spell (&optional pos buffer)
  (v2a--read-content-between "+" "#" pos buffer))
;; (v2a-read-spell nil "默认生词本.txt")

(defun v2a-read-meaning (&optional pos buffer)
  (let ((meanings (v2a--read-content-between "#" "&" pos buffer)))
    (replace-regexp-in-string "[\n#]+" "<br>" meanings)))
;; (v2a-read-meaning 81338 "默认生词本.txt")

(defun v2a-read-phonetic (&optional pos buffer)
  (v2a--read-content-between "&" "@" pos buffer))
;; (v2a-read-phonetic nil "默认生词本.txt")

(defun v2a-print-vocabulary (vocabulary &optional seperator)
  (let ((seperator (or seperator "\t")))
    (princ (concat (funcall #'string-join vocabulary seperator) "\n"))))

(defun v2a-write-vocabulary (vocabulary &optional seperator)
  (let ((seperator (or seperator "\t")))
    (insert (funcall #'string-join vocabulary seperator) "\n")))

;; (v2a-write-vocabulary (v2a-read-vocabulary 0 "默认生词本.txt"))

(defun vocabulary2anki (vocabulary-file anki-file)
  (let (vocabulary
        vocabularies)
    (with-temp-buffer
      (insert-file-contents vocabulary-file)
      (goto-char (point-min))
      (while (setq vocabulary (ignore-errors (v2a-read-vocabulary)))
        (push vocabulary vocabularies)))
    (with-temp-file anki-file
      (mapc #'v2a-write-vocabulary vocabularies))))

;; (vocabulary2anki "/cygdrive/c/默认生词本.txt" "我的生词本")

(when command-line-args-left
  (let ((vocabulary-file (pop command-line-args-left))
        (vocabulary))
    (with-temp-buffer
      (insert-file-contents vocabulary-file)
      (goto-char (point-min))
      (while (setq vocabulary (ignore-errors (v2a-read-vocabulary)))
        (v2a-print-vocabulary vocabulary))))
  (setq command-line-args-left nil))
