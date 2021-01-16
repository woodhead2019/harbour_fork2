/*
 * Alert(), hb_Alert() functions
 *
 * Released to Public Domain by Vladimir Kazimirchik <v_kazimirchik@yahoo.com>
 * Further modifications 1999-2017 Viktor Szakats (vsz.me/hb)
 *    Changes for higher Clipper compatibility, console mode, extensions, __NoNoAlert()
 *
 */

#include "box.ch"
#include "color.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "hbgtinfo.ch"

/* FIXME: Clipper defines a clipped window for Alert() [vszakats] */

/* NOTE: Clipper will return NIL if the first parameter is not a string, but
         this is not documented. [vszakats] */

/* NOTE: Clipper handles these buttons { "Ok", "", "Cancel" } in a buggy way.
         This is fixed. [vszakats] */

#ifdef HB_CLP_UNDOC
STATIC s_lNoAlert
#endif

FUNCTION Alert( cMessage, aOptions, xColorNorm )

   LOCAL xColorHigh
   LOCAL aOptionsOK
   LOCAL cOption
   LOCAL nPos

#ifdef HB_CLP_UNDOC

   IF s_lNoAlert == NIL
      s_lNoAlert := hb_argCheck( "NOALERT" )
   ENDIF

   IF s_lNoAlert
      RETURN NIL
   ENDIF

#endif

   IF ! HB_ISSTRING( cMessage )
      RETURN NIL
   ENDIF

   cMessage := StrTran( cMessage, ";", Chr( 10 ) )

   IF HB_ISSTRING( xColorNorm ) .AND. ! Empty( xColorNorm )
      xColorNorm := hb_ColorIndex( xColorNorm, CLR_STANDARD )
      xColorHigh := hb_StrReplace( ;
         iif( ( nPos := hb_BAt( "/", xColorNorm ) ) > 0, ;
            hb_BSubStr( xColorNorm, nPos + 1 ) + "/" + hb_BLeft( xColorNorm, nPos - 1 ), ;
            "N/" + xColorNorm ), "+*" )
   ELSE
      xColorNorm := 0x4f  // first pair color (Box line and Text)
      xColorHigh := 0x1f  // second pair color (Options buttons)
   ENDIF

   aOptionsOK := {}
   FOR EACH cOption IN hb_defaultValue( aOptions, {} )
      IF HB_ISSTRING( cOption ) .AND. ! Empty( cOption )
         AAdd( aOptionsOK, cOption )
      ENDIF
   NEXT

   DO CASE
   CASE Len( aOptionsOK ) == 0
      aOptionsOK := { "Ok" }
#ifdef HB_CLP_STRICT
   CASE Len( aOptionsOK ) > 4  /* NOTE: Clipper allows only four options [vszakats] */
      ASize( aOptionsOK, 4 )
#endif
   ENDCASE

   RETURN hb_gtAlert( cMessage, aOptionsOK, xColorNorm, xColorHigh )

/* NOTE: xMessage can be of any type, xColorNorm can be numeric.
         These are Harbour extensions over Alert(). */
/* NOTE: nDelay parameter is a Harbour extension over Alert(). */

FUNCTION hb_Alert( xMessage, aOptions, xColorNorm, nDelay )

   LOCAL cMessage
   LOCAL xColorHigh
   LOCAL aOptionsOK
   LOCAL cString
   LOCAL nPos

#ifdef HB_CLP_UNDOC

   IF s_lNoAlert == NIL
      s_lNoAlert := hb_argCheck( "NOALERT" )
   ENDIF

   IF s_lNoAlert
      RETURN NIL
   ENDIF

#endif

   IF PCount() == 0
      RETURN NIL
   ENDIF

   DO CASE
   CASE HB_ISARRAY( xMessage )
      cMessage := ""
      FOR EACH cString IN xMessage
         cMessage += iif( cString:__enumIsFirst(), "", Chr( 10 ) ) + hb_CStr( cString )
      NEXT
   CASE HB_ISSTRING( xMessage )
      cMessage := StrTran( xMessage, ";", Chr( 10 ) )
   OTHERWISE
      cMessage := hb_CStr( xMessage )
   ENDCASE

   IF HB_ISSTRING( xColorNorm ) .AND. ! Empty( xColorNorm )
      xColorNorm := hb_ColorIndex( xColorNorm, CLR_STANDARD )
      xColorHigh := hb_StrReplace( ;
         iif( ( nPos := hb_BAt( "/", xColorNorm ) ) > 0, ;
            hb_BSubStr( xColorNorm, nPos + 1 ) + "/" + hb_BLeft( xColorNorm, nPos - 1 ), ;
            "N/" + xColorNorm ), "+*" )
   ELSEIF HB_ISNUMERIC( xColorNorm )
      xColorNorm := hb_bitAnd( xColorNorm, 0xff )
      xColorHigh := hb_bitAnd( ;
         hb_bitOr( ;
            hb_bitShift( xColorNorm, -4 ), ;
            hb_bitShift( xColorNorm,  4 ) ), 0x77 )
   ELSE
      xColorNorm := 0x4f  // first pair color (Box line and Text)
      xColorHigh := 0x1f  // second pair color (Options buttons)
   ENDIF

   aOptionsOK := {}
   FOR EACH cString IN hb_defaultValue( aOptions, {} )
      IF HB_ISSTRING( cString ) .AND. ! cString == ""
         AAdd( aOptionsOK, cString )
      ENDIF
   NEXT

   DO CASE
   CASE Len( aOptionsOK ) == 0
      aOptionsOK := { "Ok" }
#ifdef HB_CLP_STRICT
   CASE Len( aOptionsOK ) > 4  /* NOTE: Clipper allows only four options [vszakats] */
      ASize( aOptionsOK, 4 )
#endif
   ENDCASE

   RETURN hb_gtAlert( cMessage, aOptionsOK, xColorNorm, xColorHigh, nDelay )

#ifdef HB_CLP_UNDOC

PROCEDURE __NoNoAlert()

   s_lNoAlert := .F.

   RETURN

#endif
