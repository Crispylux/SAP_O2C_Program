*&---------------------------------------------------------------------*
* 모듈/서브모듈   : SD/SDC
* Program ID : ZR19A00050
* Desc       : Display Billing Document
* Transaction: ZR19A00050
* Creator    : REM0019
* Create day  : 2026.01.17
*&---------------------------------------------------------------------*
*              변경이력
*-------  ----------    ---------------   -----------------------------
* No      Changed On    Changed by        C?R Number
* New     2026.01.20      정세영             최초작성
*&---------------------------------------------------------------------*
* <메모장>
* display
*&---------------------------------------------------------------------*

REPORT ZR19A00050.

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
TABLES : VBRK, VBRP.

DATA: gt_zVBRK19 TYPE TABLE OF ZVBRK19, "ZVBRK19(H) + bi문서번호
      gt_zVBRP19 TYPE TABLE OF ZVBRP19, "ZVBRP19(I)

      "중간 테이블
      gt_zVBRP19_t TYPE TABLE OF ZVBRP19 WITH NON-UNIQUE SORTED KEY idx01
      COMPONENTS VBELN.


"~시작 화면~
SELECT-OPTIONS:
  so_vbeln FOR VBRK-VBELN,              "sales document
  so_erdat FOR VBRK-ERDAT OBLIGATORY.   "created on




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
*
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM 1000_onli .
  DATA: lt_zVBRK19 TYPE TABLE OF ZVBRK19, "do(h)
        lt_VBRP TYPE TABLE OF VBRP WITH NON-UNIQUE SORTED KEY idx01
          COMPONENTS VBELN.

  DATA: lt_zvbrp19 TYPE TABLE OF ZVBRP19. "bi(i(

  REFRESH: gt_zVBRK19, gt_zVBRP19.



*--------------------
*~~1. 첫화면에서 받은 정보로 헤더에서 엔트리들을 가져온다~~
*--------------------
  SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_zVBRK19
  FROM ZVBRK19
  WHERE VBELN IN so_vbeln AND
        ERDAT IN so_erdat.



*--------------------
*~~(1 이용)2. 아이템들 넣기~~
*--------------------
*~2-1. ZVBRP19~
  lt_zVBRK19 = gt_zVBRK19.

  SORT lt_zVBRK19 BY VBELN.
  DELETE ADJACENT DUPLICATES FROM lt_zVBRK19 COMPARING VBELN.


  IF lt_zVBRK19 IS NOT INITIAL.
    "불러온 헤더 전체와 연결된 모든 아이템엔트리들을 중간테이블에 저장
    SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_zVBRP19_t
    FROM ZVBRP19
    FOR ALL ENTRIES IN lt_zVBRK19
    WHERE VBELN = lt_zVBRK19-VBELN. "아이템-헤더 연결



*~2-2. ZVBRP19~
    "lt_zvbrp19 라는 table 생성(DO->BI해야되니까)
    LOOP AT lt_zVBRK19 ASSIGNING FIELD-SYMBOL(<ls_zVBRK19>).
      CHECK <ls_zVBRK19>-VBELN IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_zvbrp19 ASSIGNING FIELD-SYMBOL(<ls_zvbrp19>).
      <ls_zvbrp19>-VGBEL = <ls_zVBRK19>-VBELN. "DO->BI
    ENDLOOP.



*--------------------
*~~4. 아이템이 없는 헤더는 삭제(DELETE)처리한다.~~
*--------------------
    LOOP AT gt_zVBRK19 ASSIGNING FIELD-SYMBOL(<ls_zVBRK19_1>). "이름 중복으로 바꿈
      READ TABLE gt_zVBRP19_t TRANSPORTING NO FIELDS WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_zVBRK19_1>-VBELN.
      IF sy-subrc <> 0.
        DELETE gt_zVBRK19
          WHERE VBELN = <ls_zVBRK19_1>-VBELN.
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

  DESCRIBE TABLE gt_zVBRK19 LINES lv_cnt.
  MESSAGE s000(oo) WITH lv_cnt '건 조회되었습니다.'.

  "데이터가 있으면 호출
  IF lv_cnt > 0.
    CALL SCREEN 2000.
  ENDIF.
ENDFORM.                    " 1000_AFTE


*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       툴바, 이름 지정
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
    TABLES gt_zVBRK19
    USING 'GO_AV2000_1' go_ic2000_1
          'ZVBRK19'
          ''.

  0o_av_refresh 'GO_AV2000_1' 'X' 'X' 'X'.

  "아이템
  PERFORM 0o_av_make
   TABLES gt_zVBRP19
    USING 'GO_AV2000_2' go_ic2000_2
          'ZVBRP19' " 프로그램 내의 내부테이블을
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



*
**&---------------------------------------------------------------------*
**& av2000_1_uc_refe
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM av2000_1_uc_refe USING pv_av_name.
*
*ENDFORM.
*


*&---------------------------------------------------------------------*
*&      Form  av2000_1_cell_click
*& 헤더에서 특정 CELL(VBELN) 클릭하면 gt_zVBRK19_t에서 그 cell의 아이템만 걸러줌!
*&---------------------------------------------------------------------*
FORM av2000_1_cell_click
  USING pv_av_name
        pc_gubun
        ps_row LIKE lvc_s_row
        ps_col LIKE lvc_s_col
        ps_row_no LIKE lvc_s_roid.

  REFRESH gt_zVBRP19.

  READ TABLE gt_zVBRK19 ASSIGNING FIELD-SYMBOL(<ls_zVBRK19>) INDEX ps_row_no-row_id.
  CHECK sy-subrc = 0.

  CASE ps_col-fieldname.
    WHEN 'VBELN'.
      READ TABLE gt_zVBRP19_t TRANSPORTING NO FIELDS
        WITH TABLE KEY idx01 COMPONENTS VBELN = <ls_zVBRK19>-VBELN.

      IF sy-subrc = 0.
        LOOP AT gt_zVBRP19_t ASSIGNING FIELD-SYMBOL(<ls_zVBRP19_t>) FROM sy-tabix USING KEY idx01. "현재 인덱스부터 루프
          IF <ls_zVBRP19_t>-VBELN <> <ls_zVBRK19>-VBELN.
            EXIT.
          ENDIF.
            APPEND INITIAL LINE TO gt_zVBRP19 ASSIGNING FIELD-SYMBOL(<ls_zVBRP19>).
            MOVE-CORRESPONDING <ls_zVBRP19_t> TO <ls_zVBRP19>. "중간테이블->테이블(아이템)
        ENDLOOP.
      ENDIF.

      SORT gt_zVBRP19 BY VBELN.

      0o_av_chg_set 'GO_AV2000_2' 'X'.
    ENDCASE.
ENDFORM.
