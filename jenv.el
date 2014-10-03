   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Copyright 2014 Jack Viers																								 ;;
	 ;; 																																				 ;;
   ;; Licensed under the Apache License, Version 2.0 (the "License");					 ;;
   ;; you may not use this file except in compliance with the License.				 ;;
   ;; You may obtain a copy of the License at																	 ;;
	 ;; 																																				 ;;
   ;;     http://www.apache.org/licenses/LICENSE-2.0													 ;;
	 ;; 																																				 ;;
   ;; Unless required by applicable law or agreed to in writing, software			 ;;
   ;; distributed under the License is distributed on an "AS IS" BASIS,				 ;;
   ;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. ;;
   ;; See the License for the specific language governing permissions and			 ;;
   ;; limitations under the License.																					 ;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup jenv nil 
          "jenv is a rvm clone for java environments."
          :version "1.0.0"
)

(defcustom jenv-dir "~/.jenv"
           "The jenv install directory. Default is ~/.jenv"
           :type 'directory
           :group 'jenv)

(defcustom jenv-maven-repo-dir "~/.m2"
           "The local m2 repository directory. Default is ~/m2"
           :type 'directory
           :group 'jenv)

(defcustom jenv-candidates-subdir-name "candidates"
           "The relative directory name containing the instalation candidates."
           :type 'string
           :group 'jenv)

;; (unless (functionp 'locate-dominating-file)
;;   (defun locate-dominating-file (file name)
;;     "Look up the directory hierarchy from FILE for a file named NAME.
;; Stop at the first parent directory containing a file NAME,
;; and return the directory.  Return nil if not found."
;;     (setq file (abbreviate-file-name file))
;;     (let ((root nil)
;;           (prev-file file)
;;           (user nil)
;;           try)
;;       (while (not (or root
;;                       (null file)
;;                       (string-match locate-dominating-stop-dir-regexp file)))
;;         (setq try (file-exists-p (expand-file-name name file)))
;;         (cond (try (setq root file))
;;               ((equal file (setq prev-file file
;;                                  file (file-name-directory
;;                                        (directory-file-name file))))
;;                (setq file nil))))
;;       root))

;;   (defvar locate-dominating-stop-dir-regexp
;;     "\\`\\(?:[\\/][\\/][^\\/]+\\|/\\(?:net\\|afs\\|\\.\\.\\.\\)/\\)\\'"))

(defun jenv-get-path-regex (type) 
       "gets a regex for the given jenv install type (maven,java,tomcat,etc.)"
       (mapconcat 'identity (list type "[0-9]+\.[0-9]+\.[0-9]+[_]?[0-9]?\/bin") "\/"))

(defun jenv-get-java-path-replacemen-regex nil
       "creates a regex for splitting the path env var to facilitate java bin replacement"
       (jenv-get-path-regex "java"))

(defun jenv-get-maven-path-replacement-regex nil
       "creates a regex for splitting the path env var to facilitate maven bin replacement"
       (jenv-get-path-regex "maven"))

(defun jenv-make-java-home (version)
       "Create a path string for the java version"
       (mapconcat 'identity (list jenv-dir jenv-candidates-subdir-name "java" version) "/"))

(defun jenv-make-maven-home (version)
       "Create a path string for the maven version"
       (mapconcat 'identity (list jenv-dir jenv-candidates-subdir-name "maven" version) "/"))

(defun jenv-make-m2-bin (version)
       "Create a path string for the java version"
       (mapconcat 'identity (list (jenv-make-maven-home version) "bin") "/"))

(defun jenv-make-java-path (version)
	"Create a path using version"
	)


(defun jenv-use-java-version (version)
	"Use a jenv installed version of java"
	(message (mapconcat 'identity (list "Using java version:" version) " "))
	(setenv "JAVA_HOME" (jenv-make-java-home version))
	(setenv "PATH" (mapconcat 'identity (split-string (getenv "PATH") (jenv-get-java-path-replacemen-regex)) (concat "java/" version "/bin")))
	(setq exec-path (getenv "PATH")))

(defun jenv-use-maven-version (version)
       "Use a jenv installed version of maven"
			 (message (mapconcat 'identity (list "Using maven version:" version) ""))
			 (message (mapconcat 'identity (list "Split path on:" (jenv-get-maven-path-replacement-regex)) " "))
       (setenv "M2" (jenv-make-m2-bin version))
       (setenv "M2_HOME" (jenv-make-maven-home version))
       (setenv "M2_REPO" jenv-maven-repo-dir)
       (setenv "PATH" (mapconcat 'identity (split-string (getenv "PATH") (jenv-get-maven-path-replacement-regex)) (mapconcat 'identity (list "maven" version "bin") "/")))
       (setq exec-path (getenv "PATH")))

(defun jenv-use-java-version-interactive (version)
        "Use a jenv installed version of java, specified at the minibuffer prompt"
        (interactive "sEnter a version: ")
        (jenv-use-java-version version))

(defun jenv-find-project-home-dir-from-buffer (buff-name)
	(file-name-directory (locate-dominating-file (file-name-directory buff-name) (lambda (parent) (directory-files parent nil "pom\.xml")))))

(defun read-jenvrc nil
	"reads the jenvrc in the project dir"
	(let ((jenv-proj-dir (jenv-find-project-home-dir-from-buffer (buffer-file-name))))
		(with-temp-buffer
			(insert-file-contents (mapconcat 'identity (list jenv-proj-dir "jenvrc") "/"))
			(split-string (buffer-string) "\n" t))))

(defun jenv-parse-jenvrc (line)
	(let ((tool-and-version (split-string line "=")))
		
		(let ((tool-name (car-safe tool-and-version)))
			(let ((tool-version (car-safe (cdr-safe tool-and-version))))
				(cond ((equal tool-name "java") (jenv-use-java-version tool-version))
							((equal tool-name "maven") (jenv-use-maven-version tool-version)))))))
							 

(defun jenv-auto-set-java-env nil
	(interactive)
	(mapc 'jenv-parse-jenvrc (read-jenvrc)))

(provide 'jenv)

