<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'mycred_rank_specific_blocks' ) ) :
	class mycred_rank_specific_blocks {

		public function __construct() {

			add_action( 'mycred_init', array( $this, 'init' ) );
		}

		public function init() {

			if ( is_admin() ) {

				global $pagenow;

				$allowed_post_type = false;

				if ( ( $pagenow == 'edit.php' || $pagenow == 'post-new.php' ) && isset( $_GET['post_type'] ) && $_GET['post_type'] == MYCRED_RANK_PLUS_KEY ) {
					$allowed_post_type = true;
				} elseif ( $pagenow == 'post.php' && isset( $_GET['post'] ) && mycred_get_post_type( sanitize_text_field( wp_unslash( $_GET['post'] ) ) ) == MYCRED_RANK_PLUS_KEY ) {
					$allowed_post_type = true;
				}

				if ( $allowed_post_type ) {

					$this->load_blocks();

				}
			} else {

				$this->load_blocks();

			}
		}

		public function load_blocks() {

			wp_enqueue_style( 'mycred-rank-shortcodes' );

			add_action( 'enqueue_block_editor_assets', array( $this, 'register_assets' ) );
			add_filter( 'block_categories_all', array( $this, 'register_block_category' ), 10, 2 );

			register_block_type(
				'mycred-rank-blocks/mycred-rank-requirements',
				array( 'render_callback' => array( $this, 'render_requirements_block' ) )
			);

			register_block_type(
				'mycred-rank-blocks/mycred-rank-earners',
				array( 'render_callback' => array( $this, 'render_earners_block' ) )
			);

			register_block_type(
				'mycred-rank-blocks/mycred-rank-congratulation-message',
				array( 'render_callback' => array( $this, 'render_congratulation_message_block' ) )
			);
		}

		public function register_assets() {

			wp_enqueue_script(
				'mycred-rank-specific-blocks',
				plugins_url( 'index.js', __FILE__ ),
				array(
					'wp-blocks',
					'wp-element',
				),
				MYCRED_RANK_PLUS_VERSION
			);
		}

		public function register_block_category( $categories, $post ) {

			return array_merge(
				$categories,
				array(
					array(
						'slug'  => 'mycred-rank',
						'title' => __( 'MYCRED RANK', 'mycred' ),
					),
				)
			);
		}

		public function render_congratulation_message_block( $attributes, $content ) {

			$data = $this->get_data();

			$message = mycred_get_post_meta( $data->rank_id, 'mycred_rank_plus_congratulation_msg', true );
			$html    = '';

			if ( ! empty( $data->user_has_rank ) && ! empty( $message ) ) {

				$html = '<p class="mycred-alert success">' . esc_html( $message ) . '</p>';

			}

			return $html;
		}

		public function render_requirements_block( $attributes, $content ) {

			$data = $this->get_data();

			$html  = '<div class="mycred-rank-requirements-block">';
			$html .= $data->rank->display_requirements( $data->user_id, $data->user_has_rank );
			$html .= '</div>';

			return $html;
		}

		public function render_earners_block( $attributes, $content ) {

			$data = $this->get_data();

			$html  = '<div class="mycred-rank-earners-block">';
			$html .= $data->rank->display_earners( $data->user_has_rank, 10, true );
			$html .= '</div>';

			return $html;
		}

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

new mycred_rank_specific_blocks();
