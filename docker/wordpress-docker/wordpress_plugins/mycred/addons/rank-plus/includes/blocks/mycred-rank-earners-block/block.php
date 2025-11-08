<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Plus_Earners_Block' ) ) :
    class myCred_Rank_Plus_Earners_Block extends myCred_Rank_Block {

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
           
            ob_start();
            ?>
            <style type="text/css">
                .wp-block-mycred-rank-blocks-mycred-rank-earners-block > h6 {
                    margin: <?php esc_attr_e( $hm['top'] . " " . $hm['right'] . " " . $hm['bottom'] . " " . $hm['left'] );?>;
                    color: <?php esc_attr_e( $attr['headingColor'] );?>;
                    font-size: <?php esc_attr_e( $attr['headingFontSize'] . "px" );?>;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-earners-block > ul {
                    padding: 0px !important;
                    margin: 0px !important;
                    list-style-type: none;
                    font-size: <?php esc_attr_e( $attr['nameFontSize'] . "px" );?>;
                    color: <?php esc_attr_e( $attr['nameColor'] );?>;
                    display: inline-flex;
                    gap: <?php esc_attr_e( $attr['listGap'] . "px" );?>;
                    flex-wrap: wrap;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-earners-block > ul > li {
                    overflow: hidden;
                    text-align: center;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-earners-block > ul > li > p {
                    text-align: center;
                    margin: 0px !important;
                }
                .wp-block-mycred-rank-blocks-mycred-rank-earners-block > ul > li > img {
                    width: <?php esc_attr_e( $attr['avatarSize'] . 'px' );?>;
                    height: <?php esc_attr_e( $attr['avatarSize'] . 'px' );?>;
                    border-radius: <?php esc_attr_e( $attr['avatarRadius'] . '%' );?>;
                }
            </style>
            <div class="wp-block-mycred-rank-blocks-mycred-rank-earners-block <?php esc_attr_e( $align );?>">
                <?php $data->rank->display_earners( 
                    $data->user_id, 
                    $attr['noOfUsers'], 
                    $attr['showDisplayName'], 
                    true, 
                    $attr['headingText'],
                    $attr['showDisplayNameAs'],
                    $attr['noOfChars']
                );?>
            </div>
            <?php

            $html = ob_get_clean();

            return $html;

        }

        public function register_assets() {
            
            wp_register_script( 'mycred-rank-plus-earners-block', false, array(), MYCRED_RANK_PLUS_VERSION );

            wp_localize_script(
                'mycred-rank-plus-earners-block',
                'mrpAssetsUrl',
                array(
                    plugin_dir_url( MYCRED_RANK_PLUS_THIS ) . 'assets/'
                )
            );

            wp_enqueue_script( 'mycred-rank-plus-earners-block' );

        }

    }
endif;

new myCred_Rank_Plus_Earners_Block();