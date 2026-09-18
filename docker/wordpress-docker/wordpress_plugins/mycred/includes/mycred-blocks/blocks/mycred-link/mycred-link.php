<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_link_block') ) :
    class mycred_link_block {

        public function __construct() {

            wp_register_script(
                'mycred-link', 
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

            $content = '';
            
            if ( empty( $attributes['ctype'] ) )
                $attributes['ctype'] = 'mycred_default';

            if ( isset( $attributes['clss'] ) ) {
                $attributes['class'] = $attributes['clss'];
                unset($attributes['clss']);
            }

            if ( ! empty( $attributes['content'] ) ) {
                $content = $attributes['content'];
                unset( $attributes['content'] );    
            }

            return "[mycred_link " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]" . $content . "[/mycred_link]";

        }

    }
endif;

new mycred_link_block();