<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! class_exists('mycred_badge_plus_blocks') ) :
    class mycred_badge_plus_blocks {

        public $user_id;
        public $badge_id;
        public $badge;
        public $user_has_badge;

        public function __construct() {

            add_action( 'the_post', array( $this, 'init' ) );
        
        }

        public function init( $post ) {

            if ( is_admin() ) {

                global $pagenow;

                $allowed_post_type = false;

                if ( ( $pagenow == 'post-new.php' ) && isset( $_GET['post_type'] ) && $_GET['post_type'] == MYCRED_BADGE_PLUS_KEY ) {
                    $allowed_post_type = true;
                }
                elseif( $pagenow == 'post.php' && isset( $_GET['post'] ) && mycred_get_post_type( sanitize_text_field( wp_unslash( $_GET['post'] ) ) ) == MYCRED_BADGE_PLUS_KEY ) {
                    $allowed_post_type = true;
                }

                if ( $allowed_post_type ) {
                    
                    $this->load_blocks( $post );

                }
                
            }
            else {

                $this->load_blocks( $post );
            }

        }

        public function load_blocks( $post ) {

            $this->user_id        = get_current_user_id();
            $this->badge_id       = $post->ID;
            $this->badge          = mycred_badge_plus_object( $this->badge_id );
            $this->user_has_badge = $this->badge->user_has_badge( $this->user_id, $this->badge_id );

            add_action( 'enqueue_block_editor_assets', array( $this, 'register_assets' ) );
            add_filter( 'block_categories_all',        array( $this, 'register_block_category' ), 10, 2 );

            if ( is_singular( MYCRED_BADGE_PLUS_KEY ) ) {

                register_block_type( 
                    'mycred-badge-blocks/mycred-badge-requirements', 
                    array( 'render_callback' => array( $this, 'render_requirements_block' ) )
                );

                register_block_type( 
                    'mycred-badge-blocks/mycred-badge-earners', 
                    array( 'render_callback' => array( $this, 'render_earners_block' ) )
                );

                register_block_type( 
                    'mycred-badge-blocks/mycred-badge-congratulation-message', 
                    array( 'render_callback' => array( $this, 'render_congratulation_message_block' ) )
                );

            }

        }

        public function register_assets() {

            wp_enqueue_script(
                'mycred-badge-plus-blocks', 
                plugins_url( 'index.js', __FILE__ ), 
                array( 
                    'wp-blocks', 
                    'wp-element'
                )
            );

        }

        public function register_block_category( $categories, $post ) {

            return array_merge(
                $categories, 
                array(
                    array(
                        'slug' => 'mycred-badge-plus',
                        'title' => __( 'MYCRED BADGE PLUS', 'mycred' )
                    ),
                )
            );
        
        }

        public function render_congratulation_message_block( $attributes, $content ) {

            $message    = $this->badge->congratulation_msg;
            $html       = '';

            if ( ! empty( $this->user_has_badge ) && ! empty( $message ) ) {
                
                $html = '<p class="mycred-alert success">'. esc_html( $message ) .'</p>';

            }

            return $html;

        }

        public function render_requirements_block( $attributes, $content ) {

            $html  = '<div class="mycred-badge-requirements-block">';
            $html .= $this->badge->display_requirements( $this->user_id, $this->user_has_badge );
            $html .= '</div>';

            return $html;

        }

        public function render_earners_block( $attributes, $content ) {

            $html  = '<div class="mycred-badge-earners-block">';
            $html .= $this->badge->display_earners( $this->user_has_badge, 10, true );
            $html .= '</div>';

            return $html;

        }

    }
endif;

new mycred_badge_plus_blocks();