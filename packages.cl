#+(version= 9 0)
(sys:defpatch "aserve" 12
  "v1: 1.3.16: fix freeing freed buffer;
v2: 1.3.18: introduce allegroserve-error condition object,
    fix compression with logical pathnames;
v3: add timeout for reading request header.
v4: 1.3.20: handle connection reset and aborted errors
    properly in the client;
v5: 1.3.21: new proxy control.
v6: 1.3.23: fixes socket leak in client when the the writing
    of the initial headers and body fails.
v7: 1.3.24: Move 100-continue expectation handling until after authorization
    and an entity has been found. Allow disabling of auto handling per entity.
v8: 1.3.25: fix keep-alive timeout header: use wserver-header-read-timeout
    instead of wserver-read-request-timeout.
v9: 1.3.26: Make do-http-request merge the query part of the uri of
    requests with the query argument.
v10: 1.3.27: Make clients reading a chunked response detect an unexpected eof
    instead of busy looping.
v11: 1.3.28: Have server send a 408 Request Timeout response on timeout
    instead of closing connection. Allow client to auto-retry.
v12: 1.3.28: Fix bug in retry-on-timeout code in do-http-request."
  :type :system
  :post-loadable t)

#+(version= 8 2)
(sys:defpatch "aserve" 24
  "v1: version 1.2.67, implement keep-alive in allegroserve client;
v2: 1.2.68, obey keep-alive requests for PUT and POST requests;
v3: 1.2.69, make logging though method specialized on wserver class;
v4: 1.2.70: add support for Expect: 100-continue requests;
v5: 1.3.1: compression support, publish-directory :destination can be a
   list of directories, and various SSL improvements;
v6: 1.3.5: doc updates, make client-request-read-sequence work with
   compressed responses, delay sending headers for computed entities,
   add option to do hidden redirect to an index file in a directory,
   fix prepend-headers so that it works on windows;
v7: 1.3.7: Add :default-actions to webactions,
   Avoid polling in http-accept-thread,
   smp thread safety changes;
v8: 1.3.8: fix problem w/response handler using string output streams;
v9: 1.3.9: speed up unchunking-streams;
v10: 1.3.10: fix buffer boundary error in unchunking-streams.
v11: 1.3.11: fix log reporting of content-length when using keep-alive.
v12: 1.3.12: make aserve compatible with patch inflate.003,
             request-query cache includes external-format as a key,
             send cookies on one line as per rfc6265,
             add support for ssl CRLs;
v13: 1.3.13: improve debugging facilities;
v14: 1.3.16: fix freeing freed buffer;
v15: 1.3.18: introduce allegroserve-error condition object,
    fix compression with logical pathnames;
v16: add timeout for reading request header.
    fix compression with logical pathnames.
v17: 1.3.20: handle connection reset and aborted errors
    properly in the client;
v18: 1.3.23: fixes socket leak in client when the the writing
    of the initial headers and body fails.
v19: 1.3.24: Move 100-continue expectation handling until after authorization
    and an entity has been found. Allow disabling of auto handling per entity.
v20: 1.3.25: fix keep-alive timeout header: use wserver-header-read-timeout
    instead of wserver-read-request-timeout.
v21: 1.3.26: Make do-http-request merge the query part of the uri of
    requests with the query argument.
v22: 1.3.27: Make clients reading a chunked response detect an unexpected eof
    instead of busy looping.
v23: 1.3.28: Have server send a 408 Request Timeout response on timeout
    instead of closing connection. Allow client to auto-retry.
v24: 1.3.28: Fix bug in retry-on-timeout code in do-http-request."
  :type :system
  :post-loadable t)

#+(version= 8 1)
(sys:defpatch "aserve" 2
  "v1: version 1.2.56, large request body & multipart content type & more;
v2: version 1.2.58, fix problem introduced in 1.2.56 where the response date 
  is always the zero universal time & correctly send out the comment after
  the result code."
  :type :system
  :post-loadable t)

;; -*- mode: common-lisp; package: net.aserve -*-
;;
;; packages.cl
;;
;; copyright (c) 1986-2005 Franz Inc, Berkeley, CA  - All rights reserved.
;; copyright (c) 2002-2013 Franz Inc, Oakland, CA - All rights reserved.
;;
;; This code is free software; you can redistribute it and/or
;; modify it under the terms of the version 2.1 of
;; the GNU Lesser General Public License as published by 
;; the Free Software Foundation, as clarified by the AllegroServe
;; prequel found in license-allegroserve.txt.
;;
;; This code is distributed in the hope that it will be useful,
;; but without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  See the GNU
;; Lesser General Public License for more details.
;;
;; Version 2.1 of the GNU Lesser General Public License is in the file 
;; license-lgpl.txt that was distributed with this file.
;; If it is not present, you can access it from
;; http://www.gnu.org/copyleft/lesser.txt (until superseded by a newer
;; version) or write to the Free Software Foundation, Inc., 59 Temple Place, 
;; Suite 330, Boston, MA  02111-1307  USA

;; Description:
;;   packages and exports for AllegroServe
;;
;;- This code in this file obeys the Lisp Coding Standard found in
;;- http://www.franz.com/~jkf/coding_standards.html
;;-


; note: net.html.generator is not defined here since that's a
;  standalone package
;
(in-package :user)

(eval-when (compile load eval)
  (require :osi)
  (require :autozoom)
  (require :uri)
  #-(and allegro (version>= 6))
  (require :streamc)
  (require :inflate))

sys::
(eval-when (compile load eval)
  (defvar *user-warned-about-deflate* nil)
  (handler-case (require :deflate)
    (error (c)
      (if* (null *user-warned-about-deflate*)
	 then (format t "~&NOTE: ~@<the deflate module could not be loaded, so ~
server compression is disabled.  AllegroServe is completely functional ~
without compression.  Original error loading deflate was:~:@>~%~a~%" c)
	      (setq *user-warned-about-deflate* t)))))

(defpackage :net.aserve
  (:use :common-lisp :excl :net.html.generator :net.uri :util.zip)
  (:export
   #:allegroserve-error
   #:allegroserve-error-action
   #:allegroserve-error-result
   #:allegroserve-error-identifier
   #:authorize
   #:authorize-proxy-request
   #:authorizer
   #:base64-decode
   #:base64-encode
   #:compute-strategy
   #:computed-entity
   ;; don't export, these should be private
   ; #:debug-off		
   ; #:debug-on			
   #:denied-request
   #:enable-proxy
   #:ensure-stream-lock
   #:entity-plist
   #:failed-request
   #:form-urlencoded-to-query
   #:function-authorizer ; class
   #:function-authorizer-function
   #:get-basic-authorization
   #:get-cookie-values
   #:get-all-multipart-data
   #:get-multipart-header
   #:get-multipart-sequence
   #:get-request-body
   #:handle-request
   #:handle-uri		; add-on component..
   #:header-slot-value
   #:http-request  	; class
   #:locator		; class
   #:location-authorizer  ; class
   #:location-authorizer-patterns
   #:map-entities
   #:parse-multipart-header
   #:password-authorizer  ; class
   #:process-entity
   #:proxy-control	; class
   #:proxy-control-location
   #:proxy-control-destinations
   #:publish
   #:publish-file
   #:publish-directory
   #:publish-multi
   #:publish-prefix
   #:query-to-form-urlencoded
   #:reply-header-slot-value 
   #:run-cgi-program
   #:set-basic-authorization
   #:standard-locator
   #:unpublish-locator
   #:vhost
   #:vhost-log-stream
   #:vhost-error-stream
   #:vhost-names
   #:vhost-plist

   #:request-method
   #:request-protocol

   #:request-protocol-string
   #:request-query
   #:request-query-value
   #:request-raw-request
   #:request-raw-uri
   #:request-socket
   #:request-uri
   #:request-variable-value
   #:request-wserver
   
   #:request-reply-code
   #:request-reply-date
   #:request-reply-content-length
   #:request-reply-content-type
   #:request-reply-plist
   #:request-reply-protocol-string
   #:request-reply-strategy
   #:request-reply-stream
   #:request-has-continue-expectation
   
   #:send-100-continue
   
   #:set-cookie-header
   #:shutdown
   #:split-into-words
   #:start
   #:uridecode-string
   #:uriencode-string
   #:unpublish
   #:url-argument
   #:url-argument-alist
   #:with-http-response
   #:with-http-body
   
   #:wserver
   #:wserver-default-vhost
   #:wserver-enable-chunking
   #:wserver-enable-keep-alive
   #:wserver-external-format
   #:wserver-filters
   #:wserver-header-read-timeout
   #:wserver-locators
   #:wserver-io-timeout
   #:wserver-log-function
   #:wserver-log-stream
   #:wserver-response-timeout
   #:wserver-socket
   #:wserver-vhosts
   #:log-for-wserver

   #:*aserve-version*
   #:*default-aserve-external-format*
   #:*http-header-read-timeout*
   #:*http-io-timeout*
   #:*http-response-timeout*
   #:*mime-types*
   #:*response-continue*
   #:*response-ok*
   #:*response-created*
   #:*response-accepted*
   #:*response-non-authoritative-information*
   #:*response-no-content*
   #:*response-partial-content*
   #:*response-moved-permanently*
   #:*response-found*
   #:*response-see-other*
   #:*response-not-modified*
   #:*response-temporary-redirect*
   #:*response-bad-request*
   #:*response-unauthorized*
   #:*response-not-found*
   #:*response-method-not-allowed*
   #:*response-request-timeout*
   #:*response-requested-range-not-satisfiable*
   #:*response-expectation-failed*
   #:*response-internal-server-error*
   #:*response-not-implemented*
   #:*wserver*))


(defpackage :net.aserve.client 
  (:use :net.aserve :excl :common-lisp)
  (:export 
   #:client-request  ; class
   #:client-request-close
   #:client-request-cookies
   #:client-request-headers
   #:client-request-protocol
   #:client-request-read-sequence
   #:client-request-response-code
   #:client-request-response-comment
   #:client-request-socket
   #:client-request-uri
   #:client-response-header-value
   #:read-response-body
   #:compute-digest-authorization
   #:cookie-item
   #:cookie-item-expires
   #:cookie-item-name
   #:cookie-item-path
   #:cookie-item-secure
   #:cookie-item-value
   #:cookie-jar     ; class
   #:digest-authorization
   #:digest-password
   #:digest-realm
   #:digest-username
   #:do-http-request
   #:http-copy-file
   #:make-http-client-request
   #:read-client-response-headers
   ))
