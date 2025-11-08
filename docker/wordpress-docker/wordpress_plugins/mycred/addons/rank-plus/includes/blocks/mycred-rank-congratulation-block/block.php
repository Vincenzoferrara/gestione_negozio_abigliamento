<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Plus_Congratulation_Block' ) ) :
    class myCred_Rank_Plus_Congratulation_Block extends myCred_Rank_Block {

        /**
         * Construct
         */
        function __construct() {

            parent::__construct( array(
                'block_id'   => __DIR__,
                'is_dynamic' => true
            ) );

        }

        public function render_block( $attributes, $content ) {

            return ! empty( $this->get_data()->user_has_rank ) ? $content : '';

        }

    }
endif;

new myCred_Rank_Plus_Congratulation_Block();