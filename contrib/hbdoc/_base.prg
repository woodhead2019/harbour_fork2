/*
 * Document generator base class
 *
 * Copyright 2009 April White <bright.tigra gmail.com>
 * Copyright 1999-2003 Luiz Rafael Culik <culikr@uol.com.br> (Portions of this project are based on hbdoc)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file LICENSE.txt.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

/* Optimizations */
#pragma -km+
#pragma -ko+

#include "hbclass.ch"
#include "hbver.ch"

#define I_( x )  hb_UTF8ToStr( hb_i18n_gettext( x /*, _SELF_NAME_ */ ) )

#define DOCUMENT_  1
#define INDEX_     2

CREATE CLASS TPLGenerate

   METHOD NewIndex( cDir, cFilename, cTitle, cExtension, cLang, hComponents )
   METHOD NewDocument( cDir, cFilename, cTitle, cExtension, cLang, hComponents )
   METHOD AddEntry( hEntry ) INLINE HB_SYMBOL_UNUSED( hEntry ), NIL
   METHOD AddReference( hEntry ) INLINE HB_SYMBOL_UNUSED( hEntry ), NIL
   METHOD BeginSection( cSection, cFilename ) INLINE HB_SYMBOL_UNUSED( cSection ), HB_SYMBOL_UNUSED( cFilename ), ::nDepth++
   METHOD EndSection( cSection, cFilename ) INLINE HB_SYMBOL_UNUSED( cSection ), HB_SYMBOL_UNUSED( cFilename ), ::nDepth--
   METHOD Generate()
   METHOD IsIndex() INLINE ::nType == INDEX_
   METHOD BeginTOC() INLINE Self
   METHOD EndTOC() INLINE Self
   METHOD BeginTOCItem( cName, cID ) INLINE HB_SYMBOL_UNUSED( cName ), HB_SYMBOL_UNUSED( cID ), Self
   METHOD EndTOCItem() INLINE Self
   METHOD SubCategory( cCategory, cID ) INLINE HB_SYMBOL_UNUSED( cCategory ), HB_SYMBOL_UNUSED( cID ), Self
   METHOD BeginContent() INLINE Self
   METHOD EndContent() INLINE Self
   METHOD BeginIndex() INLINE Self
   METHOD EndIndex() INLINE Self
   METHOD AddIndexItem( cName, cID ) INLINE HB_SYMBOL_UNUSED( cName ), HB_SYMBOL_UNUSED( cID ), Self

   VAR cFilename AS STRING
   VAR bBaseTitle INIT {|| I_( "%1$s Reference Guide" ) }

   HIDDEN:

   METHOD New( cDir, cFilename, cTitle, cExtension, cLang, nType, hComponents )

   PROTECTED:

   VAR nType AS INTEGER
   VAR nDepth AS INTEGER INIT 0

   VAR cFile AS STRING INIT ""
   VAR cDir AS STRING
   VAR cTitle AS STRING
   VAR cExtension AS STRING
   VAR cLang AS STRING
   VAR cOutFilename AS STRING

   VAR hComponents

ENDCLASS

METHOD NewIndex( cDir, cFilename, cTitle, cExtension, cLang, hComponents ) CLASS TPLGenerate

   ::New( cDir, cFilename, cTitle, cExtension, cLang, INDEX_, hComponents )

   RETURN Self

METHOD NewDocument( cDir, cFilename, cTitle, cExtension, cLang, hComponents ) CLASS TPLGenerate

   ::New( cDir, cFilename, cTitle, cExtension, cLang, DOCUMENT_, hComponents )

   RETURN Self

METHOD New( cDir, cFilename, cTitle, cExtension, cLang, nType, hComponents ) CLASS TPLGenerate

   ::cLang := hb_defaultValue( cLang, "en" )
   ::cDir := hb_DirSepAdd( cDir ) + iif( hb_asciiLower( ::cLang ) == "en", "", Lower( StrTran( ::cLang, "_", "-" ) ) + hb_ps() )
   ::cFilename := cFilename
   ::cTitle := cTitle
   ::cExtension := cExtension
   ::nType := nType
   ::hComponents := hComponents

   ::cOutFilename := ::cDir + ::cFilename + ::cExtension

   RETURN Self

METHOD Generate() CLASS TPLGenerate

   LOCAL cDir

   IF ! hb_vfDirExists( cDir := hb_FNameDir( ::cOutFilename ) )
      hb_DirBuild( cDir )
   ENDIF

   IF ! hb_MemoWrit( ::cOutFilename, ::cFile )
      OutErr( hb_StrFormat( "! Error: Cannot create file '%1$s'", ::cOutFilename ) + hb_eol() )
   ELSEIF hbdoc_reproducible()
      hb_vfTimeSet( ::cOutFilename, hb_Version( HB_VERSION_BUILD_TIMESTAMP_UTC ) )
   ENDIF

   RETURN Self
