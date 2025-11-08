<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Plus_Requirements_Block' ) ) :
    class myCred_Rank_Plus_Requirements_Block extends myCred_Rank_Block {

        /**
         * Construct
         */
        function __construct() {

            parent::__construct( array(
                'block_id'   => __DIR__,
                'is_dynamic' => true
            ) );

        }

        public function render_block( $attr, $content ) {

            $data  = $this->get_data();
            $align = ! empty( $attr['align'] ) ? 'align' . $attr['align'] : '';
            $hm    = $attr['headingMargin'];
            $lp    = $attr['listPadding'];
           
            ob_start();
            ?>
            <style type="text/css">
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > h6 {
                    color: <?php esc_attr_e( $attr['headingColor'] );?>;
                    margin: <?php esc_attr_e( $hm['top'] . " " . $hm['right'] . " " . $hm['bottom'] . " " . $hm['left'] );?>;
                    font-size: <?php esc_attr_e( $attr['headingFontSize'] . "px" );?>;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ol,
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ul {
                    list-style-type: <?php esc_attr_e( $attr['listStyleType'] );?>;
                    padding: <?php esc_attr_e( $lp['top'] . " " . $lp['right'] . " " . $lp['bottom'] . " " . $lp['left'] );?>;
                    font-size: <?php esc_attr_e( $attr['listFontSize'] . "px" );?>;
                    margin: 0px !important;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ol > li:not(.mycred-strike-off),
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ul > li:not(.mycred-strike-off) {
                    color: <?php esc_attr_e( $attr['nonCompletedColor'] );?>;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ol > li.mycred-strike-off,
                .wp-block-mycred-rank-blocks-mycred-rank-requirements-block > ul > li.mycred-strike-off {
                    text-decoration: <?php esc_attr_e( $attr['completedListDecoration'] );?>;
                    color: <?php esc_attr_e( $attr['completedColor'] );?>;
                }
            </style>
            <div class="wp-block-mycred-rank-blocks-mycred-rank-requirements-block <?php esc_attr_e( $align );?>">
                <?php $data->rank->display_requirements( $data->user_id, $data->user_has_rank, true, $attr['headingText'] );?>
            </div>
            <?php

            $html = ob_get_clean();

            return $html;

        }

    }
endif;

new myCred_Rank_Plus_Requirements_Block();