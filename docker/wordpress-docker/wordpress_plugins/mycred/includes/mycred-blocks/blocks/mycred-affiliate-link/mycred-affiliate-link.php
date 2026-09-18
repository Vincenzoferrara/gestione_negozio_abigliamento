<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_affiliate_link_block') ) :
    class mycred_affiliate_link_block {

        public function __construct() {

            wp_register_script(
                'mycred-affiliate-link', 
                plugins_url('index.js', __FILE__), 
                array( 
                    'wp-blocks', 
                    'wp-element', 
                    'wp-components', 
                    'wp-block-editor' 
                )
            );

            register_block_type( 
                __DIR__, 
                array( 'render_callback' => array( $this, 'render_block' ) )
            );
        
        }



        public function render_block( $attributes, $content ) {
            
            if ( empty( $attributes['pt_type'] ) )
                $attributes['pt_type'] = 'mycred_default';

            return "[mycred_affiliate_link " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]";
        }

    }
endif;

new mycred_affiliate_link_block();