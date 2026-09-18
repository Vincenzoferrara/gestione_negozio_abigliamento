<?php
namespace MG_Blocks;

if ( ! defined('ABSPATH') ) exit;

if ( ! class_exists('mycred_my_balance_block') ) :
    class mycred_my_balance_block {

        public function __construct() {

            wp_register_script(
                'mycred-my-balance', 
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
            
            if ( empty( $attributes['type'] ) )
                $attributes['type'] = 'mycred_default';

            if ( isset( $attributes['content'] ) ) {
                $content = $attributes['content'];
                unset( $attributes['content'] );
            }

            return "[mycred_my_balance " . mycred_blocks_functions::mycred_extract_attributes( $attributes ) . "]" . $content . "[/mycred_my_balance]";

        }

    }
endif;

new mycred_my_balance_block();