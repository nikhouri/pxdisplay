# pxdisplay.el

Draft Emacs major mode for fetching/displaying financial prices. 

* You must have the following in your `.emacs`:
  * `(setq pxdisplay-account "YOURACCOUNT")`
  * `(load "~/PATHTOFILE/pxdisplay.el")`
  * `(setq pxdisplay-token "YOURTOKEN")`
* Launch/refresh with `M-x pxdisplay-refresh`
* Creates (and updates) buffer `*pxdisplay*`
* Refresh in the `*pxdisplay*` buffer by pressing `r`

API reference: ()[http://developer.oanda.com/rest-live-v20/introduction/]
