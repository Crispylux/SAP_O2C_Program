*&---------------------------------------------------------------------*
* 모듈/서브모듈   : SD/SDC
* Program ID : ZR19A00020
* Desc       : SO(구매)로 DO(납품) 생성하기
* Transaction: ZR19A00020
* Creator    : REM0019
* Create day  : 2026.01.12
*&---------------------------------------------------------------------*
*              변경이력
*-------  ----------    ---------------   -----------------------------
* No      Changed On    Changed by        C?R Number
* New     2026.01.13    정세영                 최초작성
*&---------------------------------------------------------------------*
* <메모장>
*
* SO(구매오더) : VBAK(h), VBAP(i)
* DO(납품오더) : LIKP(h), LIPS(i)
*
* VBAK:VBELN-LIPS:VGBAL
*&---------------------------------------------------------------------*
REPORT ZR19A00020.

*~만능도구상자~
INCLUDE : yg1000,                                " 개발 공용 Include
            yg1000_cn,                           " CoNtainer Include
              yg1000_av.

*ALV
DATA : go_dc2000_1 TYPE REF TO cl_gui_docking_container,    "#EC NEEDED
       go_sc2000_1 TYPE REF TO cl_gui_splitter_container,   "#EC NEEDED
       go_ic2000_1 TYPE REF TO cl_gui_container,            "#EC NEEDED
       go_av2000_1 TYPE REF TO cl_gui_alv_grid,             "#EC NEEDED
       go_ic2000_2 TYPE REF TO cl_gui_container,            "#EC NEEDED
       go_av2000_2 TYPE REF TO cl_gui_alv_grid,             "#EC NEEDED
       go_ic2000_3 TYPE REF TO cl_gui_container,            "#EC NEEDED
       go_tx2000_1 TYPE REF TO cl_gui_textedit.             "#EC NEEDED

*~선언부~
TABLES : VBAK, VBAP.
DATA : gt_zvbak19 TYPE TABLE OF ZVBAK19, "ZVBAK19(H)
       gt_zvbap19 TYPE TABLE OF ZVBAP19, "ZVBAP19(I)

      "중간 테이블
       gt_vbap_t TYPE TABLE OF ZVBAP19 WITH NON-UNIQUE SORTED KEY idx01
        COMPONENTS VBELN.

*~SO-DO LINK(중복확인)~
DATA: gt_crdo TYPE TABLE OF ZLIPS19 WITH NON-UNIQUE SORTED KEY idx01
        COMPONENTS VGBEL.

*~60에서 이름과 버튼 쪽 수정하기 위해서!~
DATA gv_display_60 TYPE c.


*~시작 화면~
SELECT-OPTIONS:
  so_vbeln FOR  VBAK-VBELN,  "sales document
  so_erdat FOR  VBAK-ERDAT OBLIGATORY. "created on




*----------------------------------------------------------------------*
* INITIALIZATION.   - 프로그램 시작하기 전처리
*----------------------------------------------------------------------*
INITIALIZATION.
CLEAR gv_display_60.
IMPORT gv_display_60 FROM MEMORY ID 'DISPLAY_SO'.
FREE MEMORY ID 'DISPLAY_SO'.

*----------------------------------------------------------------------*
* START-OF-SELECTION. - 인터널테이블 만들어줌
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM 1000_onli.

*----------------------------------------------------------------------*
* END-OF-SELECTION. - ALV 보여주는역할
*----------------------------------------------------------------------*
END-OF-SELECTION.
  PERFORM 1000_afte.





*========================






*&---------------------------------------------------------------------*
*&      Form  1000_ONLI
*&---------------------------------------------------------------------*
*       인터널 테이블 만듦, 데이터 가져옴
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM 1000_onli .
  DATA: lt_vbakv TYPE TABLE OF ZVBAK19,
        lt_vbap TYPE TABLE OF VBAP WITH NON-UNIQUE SORTED KEY idx01
          COMPONENTS VBELN.

  DATA: lt_lips19v TYPE TABLE OF ZLIPS19.

  REFRESH: gt_zvbak19, gt_zvbap19, gt_crdo.


*--------------------
*~~1. 첫화면에서 받은 정보로 헤더에서 엔트리들을 가져온다~~
*--------------------
  SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_zvbak19
    FROM ZVBAK19
    WHERE VBELN IN so_vbeln AND
         ERDAT IN so_erdat.



*--------------------
*~~(1 이용)2. 아이템들 넣기~~
*--------------------
*~~ZVBAP19 쿼리~~
*~lt_vbakv 정렬 후 중복제거~
  lt_vbakv = gt_zvbak19.
  SORT lt_vbakv BY VBELN.
  DELETE ADJACENT DUPLICATES FROM lt_vbakv COMPARING VBELN.

  IF lt_vbakv IS NOT INITIAL.
    "FAE를 써서 조회한 헤더 전체와 연결된 모든 아이템 엔트리들을 중간테이블에 저장함(나중에 셀클릭form에서 걸러줌)
    SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_vbap_t
    FROM ZVBAP19
      FOR ALL ENTRIES IN lt_vbakv
    WHERE VBELN = lt_vbakv-vbeln.


*여기를 잘 모르겠음(VBAK-LIPS 연결되나?)
*~~ZLIPS19 쿼리~~
*SO->DO
    LOOP AT lt_vbakv ASSIGNING FIELD-SYMBOL(<ls_vbakv>).
      CHECK <ls_vbakv>-vbeln IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_lips19v ASSIGNING FIELD-SYMBOL(<ls_lips19v>).
      <ls_lips19v>-VGBEL = <ls_vbakv>-VBELN. "LIPS:VGBAL, VBAK:VBELN -> 이게되나...?
    ENDLOOP.


*--------------------
*~~3. gt_crdo~~
*--------------------
    SORT lt_lips19v BY VGBEL.
    DELETE ADJACENT DUPLICATES FROM lt_lips19v COMPARING VGBEL.

    IF lt_lips19v IS NOT INITIAL.
      SELECT VGBEL VBELN
        INTO CORRESPONDING FIELDS OF TABLE gt_crdo
        FROM ZLIPS19
        FOR ALL ENTRIES IN lt_lips19v
        WHERE VGBEL = lt_lips19v-VGBEL.
    ENDIF.


*--------------------
*~~4. gt_zvbak19로 -> GT_ZVBAP19를 만들때 이때 아이템이 없는 헤더는 삭제(DELETE)처리한다.~~
*--------------------
    LOOP AT gt_zvbak19 ASSIGNING FIELD-SYMBOL(<ls_vbak>).
      READ TABLE gt_vbap_t TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_vbak>-vbeln.
      IF sy-subrc <> 0.
        DELETE gt_zvbak19                     "delete sql구문
          WHERE VBELN = <ls_vbak>-VBELN.
      ENDIF.
    ENDLOOP.


  ENDIF.

ENDFORM.                    " 1000_ONLI


*&---------------------------------------------------------------------*
*&      Form  1000_AFTE
*&---------------------------------------------------------------------*
*       처음 실행 시 헤더 테이블의 엔트리가 몇 건 조회되었는지 띄운다
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM 1000_afte .
  DATA: lv_cnt TYPE i.

  CHECK sy-batch = zlea_.

  DESCRIBE TABLE gt_zvbak19 LINES lv_cnt.
  MESSAGE s000(oo) WITH lv_cnt '건 조회되었습니다.'.

  "데이터가 있으면 호출
  IF lv_cnt > 0.
    CALL SCREEN 2000.
  ENDIF.
ENDFORM.                    " 1000_AFTE


*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       툴바, 이름 지정 (60분기 추가함!)
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.

  IF gv_display_60 = 'X'.           "60쪽 보여줌
    SET PF-STATUS 'DISP'.
    SET TITLEBAR 'DISPL_TITLE'.
  ELSE.
    SET PF-STATUS '2000'. "툴바      "20에서 보여줌(여기!)
    SET TITLEBAR '2000'.  "이름
  ENDIF.


ENDMODULE.                 " STATUS_2000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  AV2000_X_MAKE  OUTPUT
*&---------------------------------------------------------------------*
*       그리드를 나눈다
*----------------------------------------------------------------------*
MODULE av2000_x_make OUTPUT.
  0o_dc_make : 'GO_DC2000_1' 1 2500.          "docking container

  0o_sc_make : 'GO_SC2000_1' go_dc2000_1 2 1. "split container

  0o_ic_make : 'GO_IC2000_1' go_sc2000_1 1 1, "inner container
               'GO_IC2000_2' go_sc2000_1 2 1.

  "헤더
  PERFORM 0o_av_make
    TABLES gt_zvbak19
    USING 'GO_AV2000_1' go_ic2000_1
          'ZVBAK19'
          ''.

  0o_av_refresh 'GO_AV2000_1' 'X' 'X' 'X'.

  "아이템
  PERFORM 0o_av_make
   TABLES gt_zvbap19
    USING 'GO_AV2000_2' go_ic2000_2
          'ZVBAP19' " 프로그램 내의 내부테이블을
*                      이용해서 필드카테고리를 정의할 수 있다.
          ''.

  0o_av_refresh 'GO_AV2000_2' 'X' 'X' 'X'.
ENDMODULE.                 " AV2000_X_MAKE  OUTPUT


*&---------------------------------------------------------------------*
*&      Form  av2000_1_set_before
*&---------------------------------------------------------------------*
FORM av2000_1_set_before USING pv_av_name.                  "#EC *



ENDFORM.                    "av2000_1_set_before


*&---------------------------------------------------------------------*
*&      Form  av2000_2_set_before
*&---------------------------------------------------------------------*
*       YG1000_AV에서 PERFORM 되고 있음
*----------------------------------------------------------------------*
FORM av2000_2_set_before USING pv_av_name.                  "#EC *

  gs_zs_av_layout-no_toolbar = 'X'.

ENDFORM.                    "av2000_2_set_before


*&---------------------------------------------------------------------*
*&      Form  av2000_1_cell_click
*& 헤더에서 특정 CELL(VBELN) 클릭하면 gt_ekpo_t에서 그 cell의 아이템만 걸러줌!
*&---------------------------------------------------------------------*
FORM av2000_1_cell_click
  USING pv_av_name
        pc_gubun
        ps_row LIKE lvc_s_row
        ps_col LIKE lvc_s_col
        ps_row_no LIKE lvc_s_roid.

  REFRESH gt_zvbap19.

  READ TABLE gt_zvbak19 ASSIGNING FIELD-SYMBOL(<ls_vbak>) INDEX ps_row_no-row_id.
  CHECK sy-subrc = 0.

  CASE ps_col-fieldname.
    WHEN 'VBELN'.
      READ TABLE gt_vbap_t TRANSPORTING NO FIELDS
        WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_vbak>-VBELN.

      IF sy-subrc = 0.
        LOOP AT gt_vbap_t ASSIGNING FIELD-SYMBOL(<ls_vbap_t>) FROM sy-tabix USING KEY idx01. "현재 인덱스부터 루프
          IF <ls_vbap_t>-VBELN <> <ls_vbak>-VBELN.
            EXIT.
          ENDIF.
            APPEND INITIAL LINE TO gt_zvbap19 ASSIGNING FIELD-SYMBOL(<ls_vbap>).
            MOVE-CORRESPONDING <ls_vbap_t> TO <ls_vbap>. "중간 테이블 -> 테이블(아이템)
        ENDLOOP.
      ENDIF.

      SORT gt_zvbap19 BY VBELN.

      0o_av_chg_set 'GO_AV2000_2' 'X'.
    ENDCASE.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  av2000_2_cell_click
*& 아이템 영역에서 셀을 클릭했을 때 뭔가 동작하도록 준비해 둔 form
*&---------------------------------------------------------------------*
FORM av2000_2_cell_click                                    "#EC *
  USING pv_av_name
        pc_gubun
        ps_row    LIKE lvc_s_row
        ps_col    LIKE lvc_s_col
        ps_row_no LIKE lvc_s_roid.

*  READ TABLE gt_eban INDEX ps_row_no-row_id.
*  CHECK sy-subrc = 0.
*
*  CASE ps_col-fieldname.
*    WHEN 'BANFN'.
*      0t_TR 'ME53N' 'X' gt_eban-banfn gt_eban-bnfpo '' '' '' '' ''.
*  ENDCASE.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  AV2000_1_CONTEXT_MENU
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*FORM av2000_1_context_menu USING pv_av_name
*                                 po_menu TYPE REF TO cl_ctmenu.
*
**- Status 로 추가 메뉴 설정할 때.
*  CALL METHOD po_menu->load_gui_status
*    EXPORTING
*      program = sy-repid
*      status  = 'AV2000_1'
*      menu    = po_menu.
*
**- 직접 명령 추가할 때.
*  CALL METHOD po_menu->add_function
*    EXPORTING
*      fcode = 'AF01'
*      text  = 'Test'.
*
** hide_functions , disable_functions 등으로 메뉴를 제어할 수 있다.
*
*ENDFORM.                    "AV2000_1_CONTEXT_MENU
*----------------------------------------------------------------------*
* 선택 삭제
*----------------------------------------------------------------------*
FORM 2000_delete.                                           "#EC CALLED

*  DATA : lt_rows LIKE lvc_s_roid OCCURS 0 WITH HEADER LINE.
*  CALL METHOD go_av2000_1->get_selected_rows
*    IMPORTING
*      et_row_no = lt_rows[].
*
*  SORT lt_rows DESCENDING BY row_id.
*
*  LOOP AT lt_rows.
*    DELETE gt_eban INDEX lt_rows-row_id.
*  ENDLOOP.
*
*  CLEAR : gs_zs_av_stbl, gt_zt_av_rows, gt_zt_av_roid.
*  CALL METHOD go_av2000_1->set_selected_rows
*    EXPORTING
*      it_index_rows            = gt_zt_av_rows
*      it_row_no                = gt_zt_av_roid
*      is_keep_other_selections = 'X'.
*
*  0o_av_chg_set 'GO_AV2000_1' abap_true.
**  LOOP AT lt_rows.
**    READ TABLE &2 INDEX lt_rows-row_id.
**    IF sy-subrc = 0.
**      MOVE-CORRESPONDING &2 TO &3.
**      APPEND &3.
**    ENDIF.
**  ENDLOOP.


ENDFORM.                    "2000_delete


*&---------------------------------------------------------------------*
*& Form av2000_1_toolbar
*&---------------------------------------------------------------------*
*& 툴바에 커스텀 버튼 추가
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_toolbar
  USING pv_av_name
        po_object TYPE REF TO cl_alv_event_toolbar_set
        pv_interactive.

  DATA: ls_tool TYPE stb_button.

  "display 화면일 경우에는 커스텀버튼x
  IF gv_display_60 = 'X'.
    RETURN.
  ENDIF.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_3.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_0.
  ls_tool-function = zlea_crdo.
  ls_tool-icon = icon_led_inactive.
  ls_tool-text = TEXT-t01.
  APPEND ls_tool TO po_object->mt_toolbar.

*  CLEAR ls_tool.
*  ls_tool-butn_type = zlea_3.
*
*  CLEAR ls_tool.
*  ls_tool-butn_type = zlea_0.
*  ls_tool-function  = zlea_refe.
*  ls_tool-icon      = icon_led_inactive.
*  ls_tool-text      = TEXT-t01.
*  APPEND ls_tool TO po_object->mT_toolbar.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form av2000_1_uc_sodo
*&---------------------------------------------------------------------*
*& create SO 버튼(zlea_crdo = CRDO)을 클릭할 때 실행되는 이벤트 처리
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_uc_crdo USING pv_av_name.

  DATA: lt_rows TYPE TABLE OF lvc_s_roid.
  DATA: lv_error.

  CALL METHOD go_av2000_1->get_selected_rows
    IMPORTING
      et_row_no = lt_rows[].

*/-- selected check validation
  PERFORM zz_get_sel_rows TABLES lt_rows
                          USING zlea_crdo
                          CHANGING lv_error.
  CHECK lv_error IS INITIAL.

*/-- selected check validation confrim dialog
  PERFORM zz_set_sel_rows TABLES lt_rows
                          USING zlea_crdo.
ENDFORM.


*&---------------------------------------------------------------------*
*& av2000_1_uc_refe
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_uc_refe USING pv_av_name.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  ZZ_GET_SEL_ROWS
*&---------------------------------------------------------------------*
*       CREATE DO를 눌렀을 때 선택 상태가 올바른지 검증! (유효성 검사)
*----------------------------------------------------------------------*
*      -->P_LT_ROWS  text
*      -->P_zlea_crdo  text
*      <--P_LV_ERROR  text
*----------------------------------------------------------------------*
FORM zz_get_sel_rows  TABLES   pt_rows STRUCTURE lvc_s_roid
                      USING    pv_ucomm
                      CHANGING pv_error.

*/--공란에러
  IF pt_rows[] IS INITIAL.
  ELSE.

* 1개건만 진행
    DESCRIBE TABLE pt_rows LINES DATA(lv_cnt).
    IF lv_cnt > 1.
      MESSAGE e000(oo) WITH 'Select only 1 row'.
    ENDIF.
  ENDIF.


  LOOP AT pt_rows ASSIGNING FIELD-SYMBOL(<ls_rows>).
    READ TABLE gt_zvbak19 ASSIGNING FIELD-SYMBOL(<ls_vbak>)
      INDEX <ls_rows>-row_id.
    IF sy-subrc = 0.

      CASE pv_ucomm.
        WHEN 'CRDO'. "DO 생성

      "8-1 : SODO 중복검사
          PERFORM zz_get_selrows_precheck USING <ls_vbak> CHANGING pv_error.


      ENDCASE.

      "8-2 : 실행시 실행할 ITEM이 없으면 LIPS-VGBEL에 LINK정보를 담아줄수 없으므로 오류처리
      READ TABLE gt_vbap_t TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_vbak>-vbeln.
      IF sy-subrc <> 0.
        pv_error = zlea_x.
        MESSAGE e000(oo) WITH 'There is no item data'.
        RETURN. "끝
      ENDIF.

    ENDIF.

  ENDLOOP.

  CHECK pv_error IS INITIAL.

  CASE pv_ucomm.
    WHEN 'CRDO'.
      PERFORM zz_set_confirm_step USING pv_ucomm CHANGING pv_error.
  ENDCASE.


ENDFORM.                    " ZZ_GET_SEL_ROWS


*&---------------------------------------------------------------------*
*&      Form  ZZ_SET_SEL_ROWS
*&---------------------------------------------------------------------*
*       검증 끝나고 실제로 so 생성
*----------------------------------------------------------------------*
*      -->P_LT_ROWS  text
*      -->P_zlea_crdo  text
*----------------------------------------------------------------------*
FORM zz_set_sel_rows  TABLES   pt_rows STRUCTURE lvc_s_roid
                      USING    pv_ucomm.

  LOOP AT pt_rows ASSIGNING FIELD-SYMBOL(<ls_rows>).
    READ TABLE gt_zvbak19 ASSIGNING FIELD-SYMBOL(<ls_vbak>)
    INDEX <ls_rows>-row_id.

    IF sy-subrc = 0.
      CASE pv_ucomm.
        WHEN 'CRDO'.
          PERFORM zz_set_sel_rows_ucomm USING pv_ucomm CHANGING <ls_vbak>.

* Screen Refresh / Reselect
          perform 1000_onli.
          0o_av_chg_set 'GO_AV2000_1' 'X'.
          0o_av_chg_set 'GO_AV2000_2' 'X'.

      ENDCASE.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " ZZ_SET_SEL_ROWS


*&---------------------------------------------------------------------*
*&      Form  ZZ_SET_CONFIRM_STEP
*&---------------------------------------------------------------------*
*       사용자 최종 확인 팝업(정말 진행하시겠습니까?)
*----------------------------------------------------------------------*
*      -->P_PV_UCOMM  text
*      <--P_PV_ERROR  text
*----------------------------------------------------------------------*
FORM zz_set_confirm_step  USING    pv_ucomm
                          CHANGING pv_error.

  DATA:   lv_textline1 TYPE spop-textline1,
          lv_textline2 TYPE spop-textline2.

  DATA: lv_answer.

  CASE pv_ucomm.
    WHEN 'CRDO'.
      lv_textline1 = TEXT-m01.
  ENDCASE.

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

  IF lv_answer <> zlea_j.
    pv_error = zlea_x.
  ENDIF.
ENDFORM.                    " ZZ_SET_CONFIRM_STEP


*&---------------------------------------------------------------------*
*&      Form  ZZ_SET_SEL_ROWS_UCOMM
*&---------------------------------------------------------------------*
*       SO->DO로 실제 DO문서 생성! (여기가 핵심)
*----------------------------------------------------------------------*
*      -->P_PV_UCOMM  text
*      <--P_<LS_VBAK>  text
*----------------------------------------------------------------------*
FORM zz_set_sel_rows_ucomm  USING    pv_ucomm
                            CHANGING ps_vbak LIKE LINE OF gt_zvbak19.

  DATA: ls_return TYPE bapiret2.
  DATA: lt_vbap TYPE ZTTVBAP19.

  lt_vbap = gt_vbap_t.

  DELETE lt_vbap WHERE vbeln <> ps_vbak-vbeln.

  CALL METHOD ZCL19_LEC_AUTO_PLAN=>ZZ_GET_DO_RTN
    EXPORTING
      IS_SO_H = ps_vbak
      IT_SO_I = lt_vbap
    IMPORTING
      ES_RETURN = ls_return.

  CASE ls_return-type.
    WHEN 'S'.
      MESSAGE s000(oo) WITH 'Sucessful Saved with' ls_return-field.
    WHEN OTHERS.
      MESSAGE s000(oo) WITH 'Fail to Save D/O Document'.
  ENDCASE.

ENDFORM.                    " ZZ_SET_SEL_ROWS_UCOMM


*&---------------------------------------------------------------------*
*&      Form  ZZ_GET_SELROWS_PRECHECK
*&---------------------------------------------------------------------*
*       SO-DO 중복여부 사전점검
*----------------------------------------------------------------------*
*      -->P_<LS_VBAK>  text
*      <--P_PV_ERROR  text
*----------------------------------------------------------------------*
FORM zz_get_selrows_precheck  USING    ps_vbak LIKE LINE OF gt_zvbak19
                              CHANGING pv_error.

  DATA: lv_vgbel TYPE LIPS-VGBEL.

  lv_vgbel = ps_vbak-VBELN.

  READ TABLE gt_crdo TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VGBEL = lv_vgbel.
  IF sy-subrc = 0.
    pv_error = zlea_x.
    MESSAGE i000(oo) WITH 'There is aleady SO-DO link exist'.
  ENDIF.

ENDFORM.                    " ZZ_GET_SELROWS_PRECHECK
