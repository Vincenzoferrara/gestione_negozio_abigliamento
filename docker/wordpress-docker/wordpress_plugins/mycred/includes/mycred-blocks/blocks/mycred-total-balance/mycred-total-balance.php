<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_total_balance_block') ) :
    class mycred_total_balance_block {

        public function __construct() {

            wp_register_script(
                'mycred-total-balance', 
                plugins_url('index.js', __FILE__), 
                array( 
                    'wp-blocks', 
                    'wp-element', 
                    'wp-components', 
                    'wp-block-editor', 
                )
            );

            register_block_type( 
                __DIR__, 
                array( 'render_callback' => array( $this, 'render_block' ) )
            );
        
        }



        public function render_block( $attributes, $content ) {
            
            if ( empty( $attributes['types'] ) )
                $attributes['types'] = 'mycred_default';

            return "[mycred_total_balance " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]";

        }

    }
endif;

new mycred_total_balance_block();