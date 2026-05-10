*&---------------------------------------------------------------------*
* 모듈/서브모듈   : SD/SDC
* Program ID : ZR19A00070
* Desc       : SY Unit Common Condition Master
* Transaction: ZR19A00070
* Creator    : REM0019
* Create day  : 2026.01.17

*&---------------------------------------------------------------------*
*              변경이력
*-------  ----------    ---------------   -----------------------------
* No      Changed On    Changed by        C?R Number
* New     2026.01.20    정세영               최초작성
*&---------------------------------------------------------------------*

REPORT zr19a00070.


* Include
INCLUDE : yg1000,                                " 개발 공용 Include
            yg1000_cn,                           " CoNtainer Include
              yg1000_av.                         " AlV Include

* 전역 변수(Tables, Data) 선언.
* 2000 ALV
DATA : go_cc2000_1 TYPE REF TO cl_gui_custom_container,
       go_av2000_1 TYPE REF TO cl_gui_alv_grid.

TABLES: zt19acom10.
DATA: gv_pcode TYPE zt19acom10-pcode VALUE 'SD_CREATE_AUTO'.
DATA: gt_itab  TYPE TABLE OF zs19a00070.

DATA: gt_name TYPE i.    "이름 틀린 개수
DATA: gv_cntinst TYPE i. "추가한 행 개수


*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECT-OPTIONS: so_pcode FOR zt19acom10-pcode
  DEFAULT gv_pcode OBLIGATORY NO-EXTENSION NO INTERVALS.

*----------------------------------------------------------------------*
* INITIALIZATION.
*----------------------------------------------------------------------*
INITIALIZATION.


*----------------------------------------------------------------------*
* START-OF-SELECTION.
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM 1000_onli.


*----------------------------------------------------------------------*
* END-OF-SELECTION.
*----------------------------------------------------------------------*
END-OF-SELECTION.
  PERFORM 1000_afte.




*&---------------------------------------------------------------------*
*& Form 1000_onli
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 1000_onli .

  REFRESH: gt_itab.

  "선언
  DATA: lt_itab TYPE TABLE OF zt18acom10.

  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE lt_itab
    FROM zt19acom10
    WHERE pcode IN so_pcode.

  IF lt_itab IS NOT INITIAL.
    LOOP AT lt_itab ASSIGNING FIELD-SYMBOL(<ls_itab>).
       APPEND INITIAL LINE TO gt_itab ASSIGNING FIELD-SYMBOL(<gs_itab>).
       MOVE-CORRESPONDING <ls_itab> to <gs_itab>.
       <gs_itab>-value2 = <ls_itab>-valu2.
       <gs_itab>-value3 = <ls_itab>-valu3.
       <gs_itab>-value4 = <ls_itab>-valu4.

       if <ls_itab>-LOEKZ = zle19_x.
         <gs_itab>-statu = zle19_d.
       ENDIF.
    ENDLOOP.
  ENDIF.

  SORT gt_itab BY pcode uname.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form 1000_afte
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 1000_afte .

  DATA: lv_cnt TYPE i.

  CHECK sy-batch IS INITIAL.

  DESCRIBE TABLE gt_itab LINES lv_cnt.

  MESSAGE s000(oo) WITH lv_cnt '건 조회되었습니다'.

  CALL SCREEN 2000.



ENDFORM.
*&---------------------------------------------------------------------*
*& Module 2000_STATUS OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE 2000_status OUTPUT.

  SET PF-STATUS '2000'.
  SET TITLEBAR  '2000'.

ENDMODULE.


*&---------------------------------------------------------------------*
*& Module AV2000_1_MAKE OUTPUT
*&---------------------------------------------------------------------*
*& 화면 ALV 구성
*&---------------------------------------------------------------------*
MODULE av2000_1_make OUTPUT.

  0o_cc_make 'GO_CC2000_1' 'GV_CX2000_1'.

  PERFORM 0o_av_make
   TABLES gt_itab
    USING 'GO_AV2000_1' go_cc2000_1 'ZS19A00070' 'X'.

  0o_av_refresh 'GO_AV2000_1' '' 'X' 'X'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Form 2000_save
*&---------------------------------------------------------------------*
*& save 버튼 클릭 시 호출
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 2000_save.

  DATA: lv_error.
  go_av2000_1->check_changed_data( ).
  DATA lv_cancel TYPE abap_bool.

  PERFORM zz_set_confirm_step CHANGING lv_cancel.
  IF lv_cancel = abap_true. "저장하시겠습니까? = NO
    EXIT.
  ENDIF.
  PERFORM zz_save_data.



ENDFORM.

*&---------------------------------------------------------------------*
*& Form 1000_afte
*&---------------------------------------------------------------------*
*& 버튼
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_toolbar
  USING pv_av_name
        po_object TYPE REF TO cl_alv_event_toolbar_set
        pv_interactive.

  DATA: ls_tool TYPE stb_button.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_3.
  APPEND ls_tool TO po_object->mt_toolbar.

  "행 삽입
  CLEAR ls_tool.
  ls_tool-butn_type = zlea_0.
  ls_tool-function  = 'INST'.
  ls_tool-icon      = icon_insert_row.
*  ls_tool-text      = 'Create S/O'.
  APPEND ls_tool TO po_object->mt_toolbar.

*  "행 삭제
*  CLEAR ls_tool.
*  ls_tool-butn_type = zlea_0.
*  ls_tool-function  = 'DELE'.
*  ls_tool-icon      = icon_delete_row.
**  ls_tool-text      = 'Create S/O'.
*  APPEND ls_tool TO po_object->mt_toolbar.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_3.
  APPEND ls_tool TO po_object->mt_toolbar.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_0.
  ls_tool-function  = 'REFE'.
  ls_tool-icon      = icon_refresh.
*  ls_tool-text      = 'Create S/O'.
  APPEND ls_tool TO po_object->mt_toolbar.

ENDFORM.


*----------------------------------------------------------------------*
* Form AV2000_1_SET_BEFORE
*----------------------------------------------------------------------*
* ※ 이 서브루틴은 동적으로 호출합니다. 삭제 전 사용처를 확인하세요.
* ※ 이 서브루틴의 파라미터는 사용하는 곳이 없더라도 삭제 하지 마세요.
*----------------------------------------------------------------------*
*            ★필수작성★ Form문 기능/내용(NXX 표기하여 작성)
*----------------------------------------------------------------------*
* N01 : GO_AV2000_1 Field Catalog, Layout, Variant, Sort 등 설정.
*----------------------------------------------------------------------*
*X : 활성화, '': 비활성화. / 필드들의 속성 정의 (여기가 필드 카탈로그)
*----------------------------------------------------------------------*
FORM av2000_1_set_before USING pv_av_name.

* GS_ZS_AV_LAYOUT
  gs_zs_av_layout-zebra = 'X'.
  gs_zs_av_layout-sel_mode = 'A'.

*시작/끝 필드이름 값
* GT_ZT_AV_FCAT
  0o_av_fcat_field : 'S' 'STATU' '',  " STATUS
                     ' ' 'COLTEXT' 'Status',
                     ' ' 'KEY' 'X',
                     'E' 'FIX_COLUMN' 'X'.

  0o_av_fcat_field : 'S' 'PCODE' '',  " Char20
                     ' ' 'COLTEXT' 'Condition Code',
                     ' ' 'KEY' 'X',
                     ' ' 'FIX_COLUMN' 'X',
                     'E' 'OUTPUTLEN' '000020'.

  0o_av_fcat_field : 'S' 'UNAME' '',  " User Name
                     ' ' 'COLTEXT' 'User ID',
                     ' ' 'KEY' 'X',
                     ' ' 'FIX_COLUMN' 'X',
                     'E' 'OUTPUTLEN' '000015'.                   "사용자 수정 가능
*                     'E' 'EDIT' 'X'.

  0o_av_fcat_field : 'S' 'VALUE1' '',  " Synch. key
                     'E' 'NO_OUT' 'X'.

  0o_av_fcat_field : 'S' 'VALUE2' '',  " Synch. key
                     'E' 'NO_OUT' 'X'.

  0o_av_fcat_field : 'S' 'VALUE3' '',  " Synch. key
                     ' ' 'COLTEXT' 'Document Auto',
                     ' ' 'CHECKBOX' 'X',                "체크박스 형태
                     ' ' 'EMPHASIZE' 'C300',            "색
                     ' ' 'OUTPUTLEN' '000015',          "컬럼 너비
                     'E' 'EDIT' 'X'.

  0o_av_fcat_field : 'S' 'VALUE4' '',  " Synch. key
                     ' ' 'COLTEXT' 'Finacial Auto',
                     ' ' 'CHECKBOX' 'X',
                     ' ' 'EMPHASIZE' 'C300',
                     ' ' 'OUTPUTLEN' '000015',
                     'E' 'EDIT' 'X'.
*
*  0o_av_fcat_field : 'S' 'PDESC' '',  "
*                     'E' 'COLTEXT' 'PCODE Desc'.

  0o_av_fcat_field : 'S' 'KDESC' '',  " Char 70
                     'E' 'NO_OUT' 'X'.

  0o_av_fcat_field : 'S' 'TDESC' '',  "
                     'E' 'NO_OUT' 'X'.

  0o_av_fcat_field : 'S' 'LOEKZ' '',  " Synch. key
                     ' ' 'COLTEXT' 'Delete Flag',
                     ' ' 'CHECKBOX' 'X',
                     ' ' 'EMPHASIZE' 'C700',
                     ' ' 'OUTPUTLEN' '000015',
                     'E' 'EDIT' 'X'. "수정 가능하게!

  0o_av_fcat_field : 'S' 'ERDAT' 'E'.  " Created on

  0o_av_fcat_field : 'S' 'ERZET' 'E'.  " Time

  0o_av_fcat_field : 'S' 'ERNAM' 'E'.  " Created By

  0o_av_fcat_field : 'S' 'AEDAT' 'E'.  " Changed On

  0o_av_fcat_field : 'S' 'AEZET' 'E'.  " Time of change

  0o_av_fcat_field : 'S' 'AENAM' 'E'.  " Changed By

ENDFORM.


*----------------------------------------------------------------------*
* Form AV2000_1_DATA_CHANGED
*----------------------------------------------------------------------*
* ※ 이 서브루틴은 동적으로 호출합니다. 삭제 전 사용처를 확인하세요.
* ※ 이 서브루틴의 파라미터는 사용하는 곳이 없더라도 삭제 하지 마세요.
*----------------------------------------------------------------------*
*            ★필수작성★ Form문 기능/내용(NXX 표기하여 작성)
*----------------------------------------------------------------------*
* N01 : GO_AV2000_1 DATA_CHANGED 이벤트 처리.
*----------------------------------------------------------------------*
* 체크박스 클릭 시 호출됨
*----------------------------------------------------------------------*
FORM av2000_1_data_changed
  USING pv_av_name
        po_change TYPE REF TO cl_alv_changed_data_protocol
        pv_onf4
        pv_onf4_before
        pv_onf4_after
        pv_ucomm.

  DATA(lt_cell) = po_change->mt_good_cells.

  LOOP AT lt_cell ASSIGNING FIELD-SYMBOL(<ls_cell>).
    READ TABLE gt_itab ASSIGNING FIELD-SYMBOL(<ls_itab>) INDEX <ls_cell>-row_id.
    IF sy-subrc = 0.
      CASE <ls_cell>-fieldname.
        WHEN 'VALUE3'.

        WHEN 'VALUE4'.

      ENDCASE.
      0o_av_mg_show po_change <ls_cell> gs_zs_return.
      MODIFY gt_itab FROM <ls_itab> INDEX <ls_cell>-row_id.
    ENDIF.
  ENDLOOP.

ENDFORM.


*----------------------------------------------------------------------*
* Form AV2000_1_CHANGED_FINISHED
*----------------------------------------------------------------------*
* ※ 이 서브루틴은 동적으로 호출합니다. 삭제 전 사용처를 확인하세요.
* ※ 이 서브루틴의 파라미터는 사용하는 곳이 없더라도 삭제 하지 마세요.
*----------------------------------------------------------------------*
*            ★필수작성★ Form문 기능/내용(NXX 표기하여 작성)
*----------------------------------------------------------------------*
* N01 : GO_AV2000_1 DATA_CHANGED_FINISHED 이벤트 처리.
*----------------------------------------------------------------------*
FORM av2000_1_changed_finished
  TABLES pt_modi STRUCTURE lvc_s_modi
   USING pv_av_name pv_modified.

  CHECK pv_modified EQ abap_true.
  LOOP AT pt_modi.
    READ TABLE gt_itab ASSIGNING FIELD-SYMBOL(<ls_itab>) INDEX pt_modi-row_id.

    IF sy-subrc EQ 0.
      CASE pt_modi-fieldname.
        WHEN 'VALUE3'.

        WHEN 'VALUE4'.

      ENDCASE.
    ENDIF.

  ENDLOOP.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form zz_set_rows_styl
*&---------------------------------------------------------------------*
*& 스타일태그 설정
*&---------------------------------------------------------------------*
*&      --> PV_UCOMM
*&      --> LV_ANSWER
*&---------------------------------------------------------------------*
Form zz_set_rows_styl CHANGING ps_itab LIKE LINE OF gt_itab.

  CASE ps_itab-statu.
    WHEN 'C'. " 신규
      0o_av_styl_set ps_itab-styl 'UNAME' gc_zc_av_gubun_e.
    WHEN OTHERS.
      0o_av_styl_set ps_itab-styl 'UNAME' gc_zc_av_gubun_f.
  ENDCASE.


ENDFORM.


*&---------------------------------------------------------------------*
*& Form av2000_1_uc_INST
*&---------------------------------------------------------------------*
*& ALV 툴바의 INST(행 추가) 버튼을 눌렀을 때 자동으로 호출되는 FORM
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_uc_INST USING pv_av_name.

  APPEND INITIAL LINE TO gt_itab ASSIGNING FIELD-SYMBOL(<gs_itab>).

  IF sy-subrc = 0.
    gv_cntinst = gv_cntinst + 1. "클릭횟수+1
  ENDIF.

  <gs_itab>-pcode = 'SD_CREATE_AUTO'.
  <gs_itab>-statu = zle19_c.

  <gs_itab>-erdat = sy-datum.
  <gs_itab>-erzet = sy-uzeit.
  <gs_itab>-ernam = sy-uname.

  PERFORM zz_set_rows_styl CHANGING <gs_itab>.

  0o_av_refresh 'GO_AV2000_1' '' 'X' 'X'.

ENDFORM.

*
**&---------------------------------------------------------------------*
**& Form av2000_1_uc_DELE
**&---------------------------------------------------------------------*
**& ALV 툴바의 DELE(행 삭제) 버튼을 눌렀을 때 자동으로 호출되는 FORM
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM av2000_1_uc_dele USING pv_av_name.
*  <gs_itab>-statu = zle19_d.
*ENDFORM.



*&---------------------------------------------------------------------*
*&      Module  2000_SCREEN  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 2000_screen OUTPUT.

ENDMODULE.                 " 2000_SCREEN  OUTPUT


*&---------------------------------------------------------------------*
*&      Form  ZZ_SAVE_DATA
*&---------------------------------------------------------------------*
*       데이터를 저장하는 FORM문
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM zz_save_data.

    DATA: lt_itab TYPE TABLE OF zt19acom10,
          lv_dummy TYPE ZT19ACOM10-UNAME,
          lv_chk TYPE i,      "실패한 행 개수
          ls_db    TYPE zt19acom10,      "원본 DB
          lv_changed TYPE abap_bool,     "변경되었는가?
          lv_newname_cnt TYPE i,         "이름이 입력된 신규행개수
          lv_blank_cnt TYPE i,"이름 공란 개수
          lv_msg TYPE string.

    CLEAR: lv_newname_cnt, lv_chk, lv_blank_cnt.

    LOOP AT gt_itab ASSIGNING FIELD-SYMBOL(<gs_itab>).

*=================
* 이름 공란 문제(uname)
*=================
      "신규 행 중 이름 입력된것만 카운트
      IF <gs_itab>-statu = zle19_c AND
        <gs_itab>-uname IS NOT INITIAL.
        lv_newname_cnt = lv_newname_cnt + 1.
      ENDIF.

      "이름 비어있으면 저장 대상 제외
      IF <gs_itab>-statu = zle19_c AND
         <gs_itab>-uname IS INITIAL.
        lv_blank_cnt = lv_blank_cnt + 1.
        CONTINUE.
      ENDIF.

*=================
* 이름 겹치는 문제(uname)
*=================
      IF <gs_itab>-statu = zle19_c AND
         <gs_itab>-uname IS NOT INITIAL.
        CLEAR lv_dummy.
        SELECT SINGLE uname INTO lv_dummy
          FROM zt19acom10
          WHERE pcode = <gs_itab>-pcode
            AND uname = <gs_itab>-uname.

        IF sy-subrc = 0.
          lv_chk = lv_chk + 1.
          CONTINUE.
        ENDIF.
      ENDIF.



*=================
* 업데이트
*=================
      "원본 DB 조회(현재 저장 전)
      CLEAR ls_db.

      SELECT SINGLE * INTO ls_db
      FROM zt19acom10
      WHERE pcode = <gs_itab>-pcode AND
            uname = <gs_itab>-uname.

      "변경되었는지?! (DB - 화면을 비교하기)
      lv_changed = abap_false.

      IF sy-subrc = 0.
        IF ls_db-valu3 <> <gs_itab>-value3 OR
           ls_db-valu4 <> <gs_itab>-value4 OR
           ls_db-loekz <> <gs_itab>-loekz.

          lv_changed = abap_true.

        ENDIF.
      ENDIF.


*=================
* DB에 저장!
*=================
    APPEND INITIAL LINE TO lt_itab ASSIGNING FIELD-SYMBOL(<ls_itab>).
    MOVE-CORRESPONDING <gs_itab> to <ls_itab>.

    <ls_itab>-valu3 = <gs_itab>-value3. "체크박스1
    <ls_itab>-valu4 = <gs_itab>-value4. "체크박스2
    <ls_itab>-loekz = <gs_itab>-loekz.  "삭제

      "초기값 아니면
    IF lv_changed = abap_true
       AND <gs_itab>-statu <> zle19_c.

      <ls_itab>-aedat = sy-datum.
      <ls_itab>-aezet = sy-uzeit.
      <ls_itab>-aenam = sy-uname.
    ENDIF.


        "쓰레기통 모양
    IF <gs_itab>-LOEKZ = 'X'.
      <gs_itab>-statu = zle19_d.
    ENDIF.
  ENDLOOP.



*=================
* 저장 실패 시 (통합본)
*=================
*: 모두 저장 불가능한 행만 있을 경우 (빈 이름, 중복 이름)
*------------------------
  IF gv_cntinst > 0 AND ( lv_newname_cnt - lv_chk ) = 0.
    gv_cntinst = 0.
    PERFORM 1000_onli.
    0o_av_chg_set 'GO_AV2000_1' 'X'.

    MESSAGE s000(oo)
    WITH  |저장 실패. 이름 공란:{ lv_blank_cnt } 이름 중복:{ lv_chk }|  DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.


*=================
* 저장(DB로 MODIFY)
*=================
*: 하나 이상 저장될 경우 불가능한 행은 날리고 가능한 행만 저장
*------------------------
    IF lt_itab IS NOT INITIAL.
      MODIFY zt19acom10 FROM TABLE lt_itab.
    ENDIF.

    MESSAGE s000(oo) WITH 'Data saved.'.

    gv_cntinst = 0. "다시 0으로
    PERFORM 1000_onli.
    0o_av_chg_set 'GO_AV2000_1' 'X'.


ENDFORM.                    " ZZ_SAVE_DATA



*&---------------------------------------------------------------------*
*&      Form  ZZ_SET_CONFIRM_STEP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM zz_set_confirm_step CHANGING pv_cancel TYPE abap_bool.
  DATA: lv_textline1 TYPE spop-textline1.
*        lv_textline2 TYPE spop-textline2.
  DATA: lv_answer.

  pv_cancel = abap_false. "yes상태임

*  CASE pv_ucomm.
*    WHEN 'CRBI'.
      lv_textline1 = TEXT-m01.
*  ENDCASE.

  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
    EXPORTING
      defaultoption  = 'N'
      textline1      = lv_textline1
*     TEXTLINE2      = ' '
      titel          = '[Saving Confirm]'
      start_column   = 55
      start_row      = 10
      cancel_display = ''
    IMPORTING
      answer         = lv_answer.

  " NO 누르면 취소
  IF lv_answer <> 'J'.
    pv_cancel = abap_true.
  ENDIF.

*  IF lv_answer <> zlea_j.
*    pv_error = zlea_x.
*  ENDIF.
ENDFORM.                    " ZZ_SET_CONFIRM_STEP
