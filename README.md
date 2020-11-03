# pxdisplay.el

Draft Emacs major mode for fetching/displaying financial prices.

![pxdisplay screenshot](pxdisplay.png)

## How to use it

* You must have the following in your `.emacs`:
  * `(load "/PATHTOFILE/pxdisplay.el")` if you don't place it in your `load-path`
  * `(setq pxdisplay-account "YOURACCOUNT")`
  * `(setq pxdisplay-token "YOURTOKEN")`
* Launch/refresh with `M-x pxdisplay-refresh`
* Refresh in the `*pxdisplay*` buffer by pressing `r`

Currently only the OANDA REST API is supported http://developer.oanda.com/rest-live-v20/introduction/
