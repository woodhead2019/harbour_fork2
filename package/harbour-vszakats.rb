class HarbourVszakats < Formula
  desc "Portable, xBase-compatible programming language and environment (vszakats fork)"
  homepage "https://github.com/vszakats/hb/"

  head "https://github.com/vszakats/hb.git"

  # Fix missing header that was deprecated by libcurl @ version 7.12.0
  # and deleted sometime after Harbour 3.0.0 release.
  stable do
    patch :DATA
    url "https://github.com/vszakats/hb/archive/v3.0.0.tar.gz"
    sha256 "34196df52c5f9994b57936fd231f09b7307462a63cfdaa42fe8d3e1a8a388dfd"
  end

  devel do
    url "https://github.com/vszakats/hb/archive/4dd7c9b22d452986a350a5d1b2652b19e85d69b5.tar.gz"
    sha256 "88a34c65e0ebd1383a51552e817d2672da8a9de87e8c239d398a5ca1354e82a7"
    version "3.4.0"
  end

  # These are "vendored", but system package used when found
  depends_on "bzip2"
  depends_on "expat"
  depends_on "libharu"
  depends_on "libmxml"
  depends_on "libpng"
  depends_on "lzo"
  depends_on "minizip"
  depends_on "pcre2"
  depends_on "sqlite"

  depends_on "cairo" => :optional
  depends_on "curl" => :optional
  depends_on "freeimage" => :optional
  depends_on "gd" => :optional
  depends_on "ghostscript" => :optional
  depends_on "icu4c" => :optional
  depends_on "libmagic" => :optional
  depends_on "libyaml" => :optional
  depends_on "mariadb" => :optional
  depends_on :mysql => :optional
  depends_on "ncurses" => :optional
  depends_on "openssl" => :optional if build.stable?
  depends_on "openssl@1.1" => :optional unless build.stable?
  depends_on :postgresql => :optional
  depends_on "qt" => :optional
  depends_on "rabbitmq-c" => :optional
  depends_on "s-lang" => :optional
  depends_on "unixodbc" => :optional
  depends_on :x11 => :optional

  def install
    ENV["HB_INSTALL_PREFIX"] = prefix
    ENV["HB_WITH_X11"] = "no" if build.without? "x11"

    system "make", "install"

    # This is no longer needed in recent builds
    rm Dir[bin/"hbmk2.*.hbl"] if build.stable?
  end

  test do
    (testpath/"hello.prg").write <<-EOS.undent
      procedure Main()
         OutStd( ;
            "Hello, world!" + hb_eol() + ;
            OS() + hb_eol() + ;
            Version() + hb_eol() )
         return
    EOS

    assert_match /Hello, world!/, shell_output("#{bin}/hbmk2 hello.prg -run")
  end
end

__END__
diff --git a/contrib/hbcurl/core.c b/contrib/hbcurl/core.c
index 00caaa8..53618ed 100644
--- a/contrib/hbcurl/core.c
+++ b/contrib/hbcurl/core.c
@@ -53,8 +53,12 @@
  */

 #include <curl/curl.h>
-#include <curl/types.h>
-#include <curl/easy.h>
+#if LIBCURL_VERSION_NUM < 0x070A03
+#  include <curl/easy.h>
+#endif
+#if LIBCURL_VERSION_NUM < 0x070C00
+#  include <curl/types.h>
+#endif

 #include "hbapi.h"
 #include "hbapiitm.h"
