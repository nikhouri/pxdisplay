(require 'json)
(require 'request)

;; User defined settings
(defvar pxdisplay-sym nil)
(defvar pxdisplay-host nil)
(defvar pxdisplay-account nil)
(defvar pxdisplay-token nil)
(if (not pxdisplay-sym) ; Default symlist if not already user-defined
    (setq pxdisplay-sym
	  '((Forex_Major (EUR_USD USD_JPY GBP_USD USD_CHF USD_CAD AUD_USD NZD_USD))
	    (Forex_Other (EUR_NOK EUR_SEK USD_CNH USD_TRY USD_ZAR USD_MXN))
	    (Indices (US30_USD SPX500_USD UK100_GBP JP225_USD EU50_EUR DE30_EUR
			       TWIX_USD HK33_HKD CN50_USD IN50_USD))
	    (Commodities (XAU_USD XAG_USD XPT_USD XCU_USD BCO_USD NATGAS_USD
				  WHEAT_USD CORN_USD SOYBN_USD SUGAR_USD))
	    (Cryptocurrency (BTC_USD)))))
(if (not pxdisplay-host) ; Default host
    ;;(setq pxdisplay-host "api-fxtrade.oanda.com") ; Live
    (setq pxdisplay-host "api-fxpractice.oanda.com")) ; Demo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; API update & display refresh code

(defun pxdisplay-OANDA-REST (host account endpoint token params successfun)
  "OANDA REST API call"
  (request
    (concat "https://" host "/v3/accounts/" account endpoint)
    :type "GET"
    :headers `(("Authorization" . ,(concat "Bearer " token)))
    :params params
    :parser 'json-read
    :timeout 5
    :success successfun
    :error (cl-function
	    (lambda (&key error-thrown &allow-other-keys&rest_)
	      (message "Error fetching rates: %S" error-thrown)))))

(defun pxdisplay-update-prices (step)
  "Main update function"
  (cond ((= step 1)
	 ;; Validate config in pxdisplay-* variables)
	 
	 ;; Initialize plists for all symbols, build symlist
	 (let ((symlist "")
	       (histlist ""))
	   (dolist (cat pxdisplay-sym)
	     (dolist (sym (cadr cat))
	       (setplist (intern (concat "pxdisplay-pxdb-" (symbol-name sym))) nil)
	       (setq symlist (concat symlist "," (symbol-name sym)))
	       (setq histlist (concat histlist "," (concat (symbol-name sym) ":D:M")
				      "," (concat (symbol-name sym) ":W:M")
				      "," (concat (symbol-name sym) ":M:M")))))
	   (put 'pxdisplay-sym 'symlist (substring symlist 1))
	   (put 'pxdisplay-sym 'histlist (substring histlist 1)))
	 ;; Fetch & process current prices
	 (message "pxdisplay-mode: updating prices...")
	 (pxdisplay-OANDA-REST pxdisplay-host pxdisplay-acct "/pricing" pxdisplay-token
			       `(("instruments" .
				  ,(get 'pxdisplay-sym 'symlist)))
			       (cl-function
				(lambda (&key data &allow-other-keys)
				  (pxdisplay-process-current data)
				  (pxdisplay-update-prices 2)))))
	((= step 2)
	 ;; Fetch & process historic prices
	 (pxdisplay-OANDA-REST pxdisplay-host pxdisplay-acct "/candles/latest" pxdisplay-token
			       `(("candleSpecifications" .
				  ,(get 'pxdisplay-sym 'histlist)))
			       (cl-function
				(lambda (&key data &allow-other-keys)
				  (pxdisplay-process-historic data)
				  (pxdisplay-update-prices 3)))))
	((= step 3)
	 ;; Update price display buffer
	 (message "pxdisplay-mode: updating prices...done")
	 (pxdisplay-update-pxdisplay))))

(defun pxdisplay-validate-setup ()
  "Validate config is well-formed, or fallback to defaults, or err out"
  t)

(defun pxdisplay-process-current (apiresult)
  "Extract current prices when REST API call returns & update symbol properties"
  (dolist (pxentry (append (alist-get 'prices apiresult) nil))
    (let ((sym (intern (concat "pxdisplay-pxdb-" (alist-get 'instrument pxentry))))
	  (bid (string-to-number (alist-get 'price (aref (alist-get 'bids pxentry) 0))))
	  (ask (string-to-number (alist-get 'price (aref (alist-get 'asks pxentry) 0))))
	  (ts (alist-get 'time pxentry)))
      (put sym 'price (/ (+ bid ask) 2))
      (put sym 'ts ts))))

(defun pxdisplay-process-historic (apiresult)
  "Extract historic prices when REST API call returns & update symbol properties"
  (dolist (pxentry (append (alist-get 'latestCandles apiresult) nil))
    (let ((sym (intern (concat "pxdisplay-pxdb-" (alist-get 'instrument pxentry))))
	  (period (intern (alist-get 'granularity pxentry)))
	  (price (string-to-number (alist-get 'c (alist-get 'mid (aref (alist-get 'candles pxentry) 0))))))
      (put sym period price))))

(defun pxdisplay-pctformat (pct)
  "Formatting pxdisplay arrowed percents"
  (if (or (floatp pct) (integerp pct))
      (cond
       ((= pct 0) "- 0.0%")
       ((> pct 0) (format "▲%+4.1f%%" (* 100 pct)))
       ((< pct 0) (format "▼%+4.1f%%" (* 100 pct)))
       "       ") ; Some other thing happened
    "       ")) ; We weren't passed a number

(defun pxdisplay-update-pxdisplay ()
  "Write out prices to a (new) *pxdisplay* buffer"
  (setq pxbuff (get-buffer-create "*pxdisplay*"))
  (with-current-buffer "*pxdisplay*"
    (setq inhibit-read-only t)
    (setq truncate-lines t)
    (setq truncate-partial-width-windows t)
    (setq cpos (point))
    (pxdisplay-mode)
    (erase-buffer)
    (dolist (cat pxdisplay-sym)
      (princ "#" pxbuff)
      (princ (car cat) pxbuff)
      (princ " \n" pxbuff)
      (if cat
	  (dolist (sym (cadr cat))
	    (let* ((fsym (intern (concat "pxdisplay-pxdb-" (symbol-name sym))))
		   (price (get fsym 'price))
		   (d (get fsym 'D))
		   (w (get fsym 'W))
		   (m (get fsym 'M))
		   (ts (get fsym 'ts)))
	      (princ (format "%-10s" sym) pxbuff)
	      (princ (format "%11.4f" price) pxbuff)
	      (princ (concat "  D:" (pxdisplay-pctformat (/ (- d price) d))) pxbuff)
	      (princ (concat "  W:" (pxdisplay-pctformat (/ (- w price) w))) pxbuff)
	      (princ (concat "  M:" (pxdisplay-pctformat (/ (- m price) m))) pxbuff)
	      (princ (concat "  (" (substring ts 0 19) "Z)") pxbuff)
	      (princ "\n" pxbuff)))))
    (read-only-mode)
    (goto-char cpos)
    (setq inhibit-read-only nil))
  (switch-to-buffer (get-buffer "*pxdisplay*")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Major mode code

(defface pxdisplay-cat
  '((t :height 1.3))
  "Face for price group header"
  :group 'pxdisplay-mode)

(defface pxdisplay-sym
  '((t :foreground "#EE7733"))
  "Face for up arrow"
  :group 'pxdisplay-mode)

(defface pxdisplay-up
  '((t :foreground "#33BBEE"))
  "Face for up arrow"
  :group 'pxdisplay-mode)

(defface pxdisplay-down
  '((t :foreground "#EE3377"))
  "Face for down arrow"
  :group 'pxdisplay-mode)

(defvar pxdisplay-highlights nil "First element for 'font-lock-defaults'")
(setq pxdisplay-highlights
      '(("^#.*" . ''pxdisplay-cat)
	("^\\([^ ]*\\) " . (1 ''pxdisplay-sym))
	(" \\(.\\):" . (1 ''bold)) ; Time period
	("▲" . ''pxdisplay-up)
	("▼" . ''pxdisplay-down)
	("(....-..-..T..:..:..Z)" . ''font-lock-comment-face)))

(defun pxdisplay ()
  "Refresh the pxdisplay"
  (interactive)
  (pxdisplay-update-prices 1))

(defvar pxdisplay-mode-map nil "Keymap for 'pxdisplay-mode'")

(progn
  (setq pxdisplay-mode-map (make-sparse-keymap))
  (define-key pxdisplay-mode-map (kbd "r") 'pxdisplay)
  (define-key pxdisplay-mode-map (kbd "R") 'pxdisplay)
  (define-key pxdisplay-mode-map (kbd "q") 'bury-buffer)
  (define-key pxdisplay-mode-map (kbd "Q") 'bury-buffer))

(define-derived-mode pxdisplay-mode text-mode "Price Display"
  "Major mode for displaying prices"
  (setq font-lock-defaults '(pxdisplay-highlights))
  (use-local-map pxdisplay-mode-map))

(provide 'pxdisplay-mode)
(provide 'pxdisplay)
