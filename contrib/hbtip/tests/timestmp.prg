/* Copyright 2009 Viktor Szakats (vsz.me/hb) */

#require "hbtip"

#include "simpleio.ch"

PROCEDURE Main()

   ? "'" + tip_TimeStamp() + "'"
   ? "'" + tip_TimeStamp( NIL, 200 ) + "'"
   ? "'" + tip_TimeStamp( Date() ) + "'"
   ? "'" + tip_TimeStamp( Date(), 200 ) + "'"
   ? "'" + tip_TimeStamp( hb_DateTime() ) + "'"
   ? "'" + tip_TimeStamp( hb_DateTime(), 200 ) + "'"

   RETURN
