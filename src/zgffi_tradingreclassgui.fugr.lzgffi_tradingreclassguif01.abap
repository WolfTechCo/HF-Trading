*----------------------------------------------------------------------*
***INCLUDE LZGFSD_TRADINGEXTGUIF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form CALL_SCREEN
*&---------------------------------------------------------------------*
FORM call_screen USING dynpro.
  CALL SCREEN dynpro.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CALL_SCREEN
*&---------------------------------------------------------------------*
FORM call_popup USING screen TYPE sy-dynnr
                      starting_x TYPE sy-tabix
                      starting_y TYPE sy-tabix
                      ending_x   TYPE sy-tabix
                      ending_y   TYPE sy-tabix.

  CALL SCREEN screen STARTING AT starting_x starting_y
                     ENDING AT ending_x ending_y.
ENDFORM.
