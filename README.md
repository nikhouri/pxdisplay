# pxdisplay.el

Draft Emacs major mode for fetching/displaying financial prices.

![pxdisplay screenshot](pxdisplay.png)

## Getting started

Add the following to your `.emacs`:
```
(add-to-list 'load-path "~/.emacs.d/pxdisplay")` ; ...or wherever you put it
(require 'pxdisplay)
(setq pxdisplay-host "HOSTNAME") ; API host, defaults to demo server if unset
(setq pxdisplay-account "YOURACCOUNT") ; Your account
(setq pxdisplay-token "YOURTOKEN")     ; Your API token
(setq pxdisplay-sym                    ; Symbol list, preset defaults if unset,
	'((LABEL1 (SYM1 SYM2 SYM3 ...))    ;   duplicate symbols in API calls fail.
	  (LABEL2 (SYM4 SYM5 SYM6 ...))))  ;   Try with the defaults first.
```
* Launch/refresh with `M-x pxdisplay`
* Refresh in the `*pxdisplay*` buffer by pressing `r`

## Notes

* Not all instrument types are available on all accounts. If you have problems, try starting with a basic symbol list (for example, just forex).
* Only the OANDA REST API is currently supported: http://developer.oanda.com/rest-live-v20/introduction/
