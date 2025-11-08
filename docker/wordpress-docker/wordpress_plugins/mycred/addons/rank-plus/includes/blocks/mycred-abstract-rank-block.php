<?php
if ( ! defined('MYCRED_RANK_PLUS_VERSION') ) exit;

if ( ! class_exists('myCred_Rank_Block') ) :
    abstract class myCred_Rank_Block {

        public $block_id;
        public $is_dynamic;

        public function __construct( $args ) {

            $this->block_id   = $args['block_id'];
            $this->is_dynamic = isset( $args['is_dynamic'] ) ? $args['is_dynamic'] : false;

            add_action( 'mycred_init', array( $this, 'init' ) );

            add_action( 'enqueue_block_editor_assets', array( $this, 'register_assets' ) );
        
        }

        public function init() {

            if ( is_admin() ) {

                global $pagenow;

                $allowed_post_type = false;

                if ( ( $pagenow == 'edit.php' || $pagenow == 'post-new.php' ) && isset( $_GET['post_type'] ) && $_GET['post_type'] == MYCRED_RANK_PLUS_KEY ) {
                    $allowed_post_type = true;
                }
                elseif( $pagenow == 'post.php' && isset( $_GET['post'] ) && mycred_get_post_type( sanitize_text_field( wp_unslash( $_GET['post'] ) ) ) == MYCRED_RANK_PLUS_KEY ) {
                    $allowed_post_type = true;
                }

                if ( $allowed_post_type ) {
                    
                    $this->load_block();

                }
                
            }
            else {

                $this->load_block();

            }

        }

        public function load_block() {

            if ( $this->is_dynamic ) {
                
                register_block_type( 
                    $this->block_id, 
                    array( 'render_callback' => array( $this, 'render_block' ) )
                );

            }
            else {

                register_block_type( $this->block_id );

            }

        }

        public abstract function render_block( $attributes, $content );

        public function register_assets() {}

        public function get_data() {

            $cache_key = 'mycred_rank_specific_blocks_data';

            $data = wp_cache_get( $cache_key );

            if ( false === $data ) {

                $data = new stdClass();

                global $post;

                $data->user_id       = get_current_user_id();
                $data->rank_id       = $post->ID;
                $data->rank          = mycred_rank( $data->rank_id );
                $data->user_has_rank = $data->rank->user_has_rank( $data->user_id );
         
                wp_cache_set( $cache_key, $data );

            }

            return $data;

        }

    }
endif;