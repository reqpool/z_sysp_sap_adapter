*&---------------------------------------------------------------------*
*& Report z_sysp_sap_adapter2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_sysp_sap_adapter2.

TABLES: tadiv.

SELECTION-SCREEN: BEGIN OF BLOCK b1.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(10) tpack.
SELECT-OPTIONS: sopack FOR tadiv-devclass default 'Z*' OPTION CP.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(10) tppath.
PARAMETERS: pfolder LIKE rlgrap-filename MEMORY ID mfolder DEFAULT 'c:/temp'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK b1.

INITIALIZATION.
  tpack  = 'Package'.
  tppath = 'Folder'.

START-OF-SELECTION.

  DATA:
    lx_error           TYPE REF TO zcx_abapgit_exception,
    lv_text            TYPE c LENGTH 200,
    ls_local_settings  TYPE zif_abapgit_persistence=>ty_repo-local_settings,
    lo_dot_abapgit     TYPE REF TO zcl_abapgit_dot_abapgit,
    lv_zip_xstring     TYPE xstring,
    lo_frontend_serv   TYPE REF TO zif_abapgit_frontend_services,
    lv_default         TYPE string,
    lv_package_escaped TYPE string,
    lv_path            TYPE string,
    iv_package         TYPE devclass.

  "ls_local_settings-main_language_only = iv_main_lang_only.

* load all matching packages
  SELECT DISTINCT t~devclass
  FROM tadir AS t INNER JOIN tdevc AS d
  ON t~devclass = d~devclass
  INTO TABLE @DATA(it_pks)
  WHERE t~devclass IN @sopack
  AND ( d~parentcl IS NULL OR d~parentcl = ' ' OR d~parentcl = '' )
  ORDER BY t~devclass.

  LOOP AT it_pks INTO iv_package.

    write: / iv_package.

    lo_frontend_serv = zcl_abapgit_ui_factory=>get_frontend_services( ).

    lv_package_escaped = iv_package.
    REPLACE ALL OCCURRENCES OF '/' IN lv_package_escaped WITH '#'.
    lv_default = |{ lv_package_escaped }_{ sy-datlo }_{ sy-timlo }|.

    TRY.
        " ls_local_settings-main_language_only = iv_main_lang_only.

        lo_dot_abapgit = zcl_abapgit_dot_abapgit=>build_default( ).
        lo_dot_abapgit->set_folder_logic( 'FULL' ).

        lv_zip_xstring = zcl_abapgit_zip=>export(
         is_local_settings = ls_local_settings
         iv_package        = iv_package
         "iv_show_log       = iv_show_log
         io_dot_abapgit    = lo_dot_abapgit ).

        "        lv_path = lo_frontend_serv->show_file_save_dialog(
        "            iv_title            = 'Package Export'
        "            iv_extension        = 'zip'
        "            iv_default_filename = lv_default ).

        CONCATENATE pfolder '/' lv_default '.zip' INTO lv_path.

        lo_frontend_serv->file_download(
            iv_path = lv_path
            iv_xstr = lv_zip_xstring ).

      CATCH zcx_abapgit_exception INTO lx_error.
        lv_text = lx_error->get_text( ).
        MESSAGE s000(oo) RAISING error WITH
          lv_text+0(50)
          lv_text+50(50)
          lv_text+100(50)
          lv_text+150(50).
    ENDTRY.

  ENDLOOP.

  write: / 'Finished downloading'.
