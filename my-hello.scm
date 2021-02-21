(define-module (gnu packages version-control)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages web)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages tls))

(define-public my-libgit2
  (let ((commit "e98d0a37c93574d2c6107bf7f31140b548c6a7bf")
        (revision "1"))
    (package
      (name "my-libgit2")
      (version (git-version "0.26.6" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/libgit2/libgit2/")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "17pjvprmdrx4h6bb1hhc98w9qi6ki7yl57f090n9kbhswxqfs7s3"))
                (patches (search-patches "libgit2-mtime-0.patch"))
                (modules '((guix build utils)))
                (snippet '(begin
                            ;; Remove bundled software.
                            (delete-file-recursively "deps")
                            #t))))
      (build-system cmake-build-system)
      (outputs '("out" "debug"))
      (arguments
       `(#:tests? #t                            ; Run the test suite (this is the default)
         #:configure-flags '("-DUSE_SHA1DC=ON") ; SHA-1 collision detection
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'fix-hardcoded-paths
             (lambda _
               (substitute* "tests/repo/init.c"
                 (("#!/bin/sh") (string-append "#!" (which "sh"))))
               (substitute* "tests/clar/fs.h"
                 (("/bin/cp") (which "cp"))
                 (("/bin/rm") (which "rm")))
               #t))
           ;; Run checks more verbosely.
           (replace 'check
             (lambda _ (invoke "./libgit2_clar" "-v" "-Q")))
           (add-after 'unpack 'make-files-writable-for-tests
               (lambda _ (for-each make-file-writable (find-files "." ".*")))))))
      (inputs
       `(("libssh2" ,libssh2)
         ("http-parser" ,http-parser)
         ("python" ,python-wrapper)))
      (native-inputs
       `(("pkg-config" ,pkg-config)))
      (propagated-inputs
       ;; These two libraries are in 'Requires.private' in libgit2.pc.
       `(("openssl" ,openssl)
         ("zlib" ,zlib)))
      (home-page "https://libgit2.github.com/")
      (synopsis "Library providing Git core methods")
      (description
       "Libgit2 is a portable, pure C implementation of the Git core methods
provided as a re-entrant linkable library with a solid API, allowing you to
write native speed custom Git applications in any language with bindings.")
      ;; GPLv2 with linking exception
      (license license:gpl2))))


