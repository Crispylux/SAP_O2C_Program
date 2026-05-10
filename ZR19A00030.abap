*&---------------------------------------------------------------------*
* 모듈/서브모듈   : SD/SDC
* Program ID : ZR19A00030
* Desc       : DO로 -> GI(GOODS ISSUE 출고)날짜 업데이트 발생
* Transaction: ZR19A00030
* Creator    : REM0019
* Create day  : 2026.01.14
*&---------------------------------------------------------------------*
*              변경이력
*-------  ----------    ---------------   -----------------------------
* No      Changed On    Changed by        C?R Number
* New     2026.01.14    정세영                 최초작성
*&---------------------------------------------------------------------*
* <메모장>
* LIKP, LIPS
* LIKP를 선택해서
* LIKP의 날짜를 업데이트(출고버튼) = WADAT_IST (LIKP에 있음)
*
*LIPS(VBELN)-VBRP(VGBEL)
*
* - update지만 create처럼 1번만 가능!(최초생성) 따라서 SO-GI LINK가 있어야함!!!
*
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
TABLES : LIKP, LIPS.
DATA : gt_zlikp19 TYPE TABLE OF ZLIKP19, "ZVBAK19(H)
       gt_zlips19 TYPE TABLE OF ZLIPS19,

      "중간 테이블
       gt_zlips19_t TYPE TABLE OF ZLIPS19 WITH NON-UNIQUE SORTED KEY idx01
        COMPONENTS VBELN.


*~SO-GI LINK(중복확인)~
DATA: gt_crgi TYPE TABLE OF ZLIKP19 WITH NON-UNIQUE SORTED KEY idx01
        COMPONENTS VBELN.

*~시작 화면~
SELECT-OPTIONS:
  so_vbeln FOR  LIKP-VBELN,  "sales document
  so_erdat FOR  LIKP-ERDAT OBLIGATORY. "created on



*----------------------------------------------------------------------*
* INITIALIZATION.
*----------------------------------------------------------------------*
INITIALIZATION.

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
  DATA: lt_zlikp19 TYPE TABLE OF ZLIKP19, "do(h)
        lt_lips TYPE TABLE OF LIPS WITH NON-UNIQUE SORTED KEY idx01
          COMPONENTS VBELN.

  DATA: lt_zvbrp19 TYPE TABLE OF ZVBRP19. "bi(i(

  REFRESH: gt_zlikp19, gt_zlips19, gt_crgi.



*--------------------
*~~1. 첫화면에서 받은 정보로 헤더에서 엔트리들을 가져온다~~
*--------------------
  SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_zlikp19
  FROM ZLIKP19
  WHERE VBELN IN so_vbeln AND
        ERDAT IN so_erdat.



*--------------------
*~~(1 이용)2. 아이템들 넣기~~
*--------------------
*~ZLIPS19~
  lt_zlikp19 = gt_zlikp19.

  SORT lt_zlikp19 BY VBELN.
  DELETE ADJACENT DUPLICATES FROM lt_zlikp19 COMPARING VBELN.


  IF lt_zlikp19 IS NOT INITIAL.
    "불러온 헤더 전체와 연결된 모든 아이템엔트리들을 중간테이블에 저장
    SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_zlips19_t
    FROM ZLIPS19
    FOR ALL ENTRIES IN lt_zlikp19
    WHERE VBELN = lt_zlikp19-VBELN. "아이템-헤더 연결


  "lt_zlikp19에는 헤더 엔트리들이 들어있음
*--------------------
*~~3. gt_crgi~~
* 계획: lt_zlikp19에서 gi(WADAT_IST)없는(create gi 안한)행은 삭제하고 gt_crgi에 lt_zlikp19(gi한 헤더) 넣을 것
*--------------------
  DELETE lt_zlikp19                   "일단 GI없는 행 삭제(CREATE GI를 하지 않음)
    WHERE WADAT_IST IS INITIAL.

  "ZLIKP19의 키조합 = (MANDT, VBELN) = 중복제거필요
  SORT lt_zlikp19 BY VBELN.
  DELETE ADJACENT DUPLICATES FROM lt_zlikp19 COMPARING VBELN.

  gt_crgi = lt_zlikp19.               "gt_crgi에 lt_zlikp19(gi한 헤더) 넣을 것



*--------------------
*~~4. 아이템이 없는 헤더는 삭제(DELETE)처리한다.~~
*--------------------
    LOOP AT gt_zlikp19 ASSIGNING FIELD-SYMBOL(<ls_zlikp19_1>). "이름 중복으로 바꿈
      READ TABLE gt_zlips19_t TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_zlikp19_1>-VBELN.
      IF sy-subrc <> 0.
        DELETE gt_zlikp19
          WHERE VBELN = <ls_zlikp19_1>-VBELN.
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

  DESCRIBE TABLE gt_zlikp19 LINES lv_cnt.
  MESSAGE s000(oo) WITH lv_cnt '건 조회되었습니다.'.

  "데이터가 있으면 호출
  IF lv_cnt > 0.
    CALL SCREEN 2000.
  ENDIF.

ENDFORM.                    " 1000_AFTE


*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       툴바, 이름
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.
  SET PF-STATUS '2000'. "툴바
  SET TITLEBAR '2000'.  "이름

ENDMODULE.                 " STATUS_2000  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  AV2000_X_MAKE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE av2000_x_make OUTPUT.
  0o_dc_make : 'GO_DC2000_1' 1 2500.          "docking container

  0o_sc_make : 'GO_SC2000_1' go_dc2000_1 2 1. "split container

  0o_ic_make : 'GO_IC2000_1' go_sc2000_1 1 1, "inner container
               'GO_IC2000_2' go_sc2000_1 2 1.

  "헤더
  PERFORM 0o_av_make
    TABLES gt_zlikp19
    USING 'GO_AV2000_1' go_ic2000_1
          'ZLIKP19'
          ''.

  0o_av_refresh 'GO_AV2000_1' 'X' 'X' 'X'.

  "아이템
  PERFORM 0o_av_make
   TABLES gt_zlips19
    USING 'GO_AV2000_2' go_ic2000_2
          'ZLIPS19' " 프로그램 내의 내부테이블을
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

  REFRESH gt_zlips19.

  READ TABLE gt_zlikp19 ASSIGNING FIELD-SYMBOL(<ls_zlikp19>) INDEX ps_row_no-row_id.
  CHECK sy-subrc = 0.

  CASE ps_col-fieldname.
    WHEN 'VBELN'.
      READ TABLE gt_zlips19_t TRANSPORTING NO FIELDS
        WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_zlikp19>-VBELN.

      IF sy-subrc = 0.
        LOOP AT gt_zlips19_t ASSIGNING FIELD-SYMBOL(<ls_zlips19_t>) FROM sy-tabix USING KEY idx01. "현재 인덱스부터 루프
          IF <ls_zlips19_t>-VBELN <> <ls_zlikp19>-VBELN.
            EXIT.
          ENDIF.
            APPEND INITIAL LINE TO gt_zlips19 ASSIGNING FIELD-SYMBOL(<ls_zlips19>).
            MOVE-CORRESPONDING <ls_zlips19_t> TO <ls_zlips19>. "중간테이블->테이블(아이템)
        ENDLOOP.
      ENDIF.

      SORT gt_zlips19 BY VBELN.

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

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_3.

  CLEAR ls_tool.
  ls_tool-butn_type = zlea_0.
  ls_tool-function = zlea_crgi.
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
*& create GI 버튼(zlea_crgi = CRGI)을 클릭할 때 실행되는 이벤트 처리
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM av2000_1_uc_crgi USING pv_av_name.

  DATA: lt_rows TYPE TABLE OF lvc_s_roid.
  DATA: lv_error.

  CALL METHOD go_av2000_1->get_selected_rows
    IMPORTING
      et_row_no = lt_rows[].

*/-- selected check validation
  PERFORM zz_get_sel_rows TABLES lt_rows
                          USING zlea_crgi
                          CHANGING lv_error.
  CHECK lv_error IS INITIAL.

*/-- selected check validation confrim dialog
  PERFORM zz_set_sel_rows TABLES lt_rows
                          USING zlea_crgi.
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
*       CREATE GI를 눌렀을 때 선택 상태가 올바른지 검증! (유효성 검사)
*----------------------------------------------------------------------*
*      -->P_LT_ROWS  text
*      -->P_ZLEA_CRGI  text
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
    READ TABLE gt_zlikp19 ASSIGNING FIELD-SYMBOL(<ls_zlikp19>)
      INDEX <ls_rows>-row_id.
    IF sy-subrc = 0.

      CASE pv_ucomm.
        WHEN 'CRGI'. "GI

      "8-1 : SOGI 중복검사
          PERFORM zz_get_selrows_precheck USING <ls_zlikp19> CHANGING pv_error.


      ENDCASE.

      "8-2 : 실행시 실행할 ITEM이 없으면 오류처리
      READ TABLE gt_zlips19_t TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_zlikp19>-vbeln.
      IF sy-subrc <> 0.
        pv_error = zlea_x.
        MESSAGE e000(oo) WITH 'There is no item data'.
        RETURN. "끝
      ENDIF.

    ENDIF.

  ENDLOOP.

  CHECK pv_error IS INITIAL.

  CASE pv_ucomm.
    WHEN 'CRGI'.
      PERFORM zz_set_confirm_step USING pv_ucomm CHANGING pv_error.
  ENDCASE.


ENDFORM.                    " ZZ_GET_SEL_ROWS



*&---------------------------------------------------------------------*
*&      Form  ZZ_SET_SEL_ROWS
*&---------------------------------------------------------------------*
*       검증 끝나고 실제로 so 생성
*----------------------------------------------------------------------*
*      -->P_LT_ROWS  text
*      -->P_ZLEA_CRGI  text
*----------------------------------------------------------------------*
FORM zz_set_sel_rows  TABLES   pt_rows STRUCTURE lvc_s_roid
                      USING    pv_ucomm.

  LOOP AT pt_rows ASSIGNING FIELD-SYMBOL(<ls_rows>).
    READ TABLE gt_zlikp19 ASSIGNING FIELD-SYMBOL(<ls_zlikp19>)
    INDEX <ls_rows>-row_id.

    IF sy-subrc = 0.
      CASE pv_ucomm.
        WHEN 'CRGI'.
          PERFORM zz_set_sel_rows_ucomm USING pv_ucomm CHANGING <ls_zlikp19>.

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
    WHEN 'CRGI'.
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
*       여기서 GI 업데이트
*----------------------------------------------------------------------*
*      -->P_PV_UCOMM  text
*      <--P_<LS_VBAK>  text
*----------------------------------------------------------------------*
FORM zz_set_sel_rows_ucomm  USING    pv_ucomm
                            CHANGING ps_likp LIKE LINE OF gt_zlikp19.

  DATA: ls_return TYPE bapiret2.

  CALL METHOD ZCL19_LEC_AUTO_PLAN=>ZZ_GET_GI_RTN

    IMPORTING
      ES_RETURN = ls_return
    CHANGING
      CS_DO_H = ps_likp.


  CASE ls_return-type.
    WHEN 'S'.
      MESSAGE s000(oo) WITH 'Sucessful GI' ls_return-field.
    WHEN OTHERS.
      MESSAGE s000(oo) WITH 'Fail to GI'.
  ENDCASE.

ENDFORM.                    " ZZ_SET_SEL_ROWS_UCOMM


*&---------------------------------------------------------------------*
*&      Form  ZZ_GET_SELROWS_PRECHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<LS_VBAK>  text
*      <--P_PV_ERROR  text
*----------------------------------------------------------------------*
FORM zz_get_selrows_precheck  USING    ps_likp LIKE LINE OF gt_zlikp19
                              CHANGING pv_error.

  DATA: lv_vbeln TYPE LIKP-VBELN.

  lv_vbeln = ps_likp-VBELN.


  "CREATE GI 한 모임임.
  READ TABLE gt_crgi TRANSPORTING NO FIELDS
    WITH TABLE KEY idx01 COMPONENTS VBELN = lv_vbeln.

  IF sy-subrc = 0.
    pv_error = zlea_x.
    MESSAGE i000(oo) WITH 'There is aleady DO-GI link exist'.
  ENDIF.

ENDFORM.                    " ZZ_GET_SELROWS_PRECHECK
