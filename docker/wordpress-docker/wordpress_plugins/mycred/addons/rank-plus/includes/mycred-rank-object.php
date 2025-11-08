<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * myCred_Rank_Object class
 *
 * @see http://codex.mycred.me/classes/myCred_Rank_Object/
 * @since 2.5
 * @version 1.0
 */
if ( ! class_exists( 'myCred_Rank_Object' ) ) :
	class myCred_Rank_Object extends myCRED_Object {

		/**
		 * Rank Post ID
		 */
		public $rank_id = false;

		/**
		 * The rank post object
		 */
		public $post = false;

		/**
		 * The Rank title
		 */
		public $title = '';

		/**
		 * Minimum point requirement for this rank
		 */
		public $requirements = null;

		/**
		 * Maximum point requirement for this rank
		 */
		public $priority = null;

		/**
		 * Total users with this rank
		 */
		public $is_default = false;

		/**
		 * The rank type object associated with this rank
		 */
		public $type = false;

		/**
		 * The ranks logo attachment id
		 */
		public $logo_id       = false;
		public $earners_count = 0;

		/**
		 * Construct
		 */
		public function __construct( $rank_id = null ) {

			parent::__construct();

			$rank_id = absint( $rank_id );

			if ( $rank_id === 0 ) {
				return;
			}

			$this->populate( $rank_id );
		}

		/**
		 * Populate
		 *
		 * @since 1.0
		 * @version 1.0
		 */
		protected function populate( $rank_id ) {

			$post = mycred_get_post( $rank_id );

			if ( empty( $post->post_type ) || $post->post_type != MYCRED_RANK_PLUS_KEY ) {
				return;
			}

			$this->rank_id       = $rank_id;
			$this->post          = $post;
			$this->title         = mycred_get_the_title( $this->post );
			$this->requirements  = mycred_get_post_meta( $this->rank_id, 'mycred_rank_requirements', true );
			$this->priority      = mycred_get_post_meta( $this->rank_id, 'mycred_rank_plus_priority', true );
			$this->is_default    = mycred_get_post_meta( $this->rank_id, 'mycred_rank_plus_is_default', true );
			$this->earners_count = mycred_get_post_meta( $this->rank_id, 'mycred_rank_earners_count', true );

			if ( empty( $this->earners_count ) || $this->earners_count < 0 ) {
				$this->earners_count = 0;
			}

			$thumbnail_id = get_post_thumbnail_id( $this->post );

			if ( ! empty( $thumbnail_id ) ) {
				$this->logo_id = $thumbnail_id;
			}

			$type = get_the_terms( $this->post, 'mycred_rank_types' );

			if ( ! empty( $type[0]->slug ) ) {
				$this->type = $type[0];
			}
		}

		/**
		 * Get Rank Logo
		 * Returns the given ranks logo.
		 *
		 * @since 1.5
		 * @version 1.0
		 */
		public function get_logo_image( $size = 'post-thumbnail', $attr = null ) {

			if ( is_numeric( $size ) ) {
				$size = array( $size, $size );
			}

			if ( mycred_override_settings() && ! mycred_is_main_site() ) {

				switch_to_blog( get_network()->site_id );

				$logo = get_the_post_thumbnail( $this->post, $size, $attr );

				restore_current_blog();

			} else {

				$logo = get_the_post_thumbnail( $this->post, $size, $attr );

			}

			return apply_filters( 'mycred_get_rank_logo_image', $logo, $this->post, $size, $attr );
		}

		/**
		 * Get Rank Logo URL
		 * Returns the given ranks logo url.
		 *
		 * @since 1.5
		 * @version 1.0
		 */
		public function get_logo_url() {

			$logo_url = '';

			if ( ! empty( $this->logo_id ) ) {
				$logo_url = wp_get_attachment_url( $this->logo_id );
			}

			return apply_filters( 'mycred_get_rank_logo_url', $logo_url, $this->logo_id, $this->post );
		}

		public function user_has_rank( $user_id ) {

			if ( empty( $user_id ) ) {
				return false;
			}

			$has_earned = mycred_get_user_meta( $user_id, 'mycred_rank_', $this->rank_id, true );

			return ! empty( $has_earned );
		}

		/**
		 * Assign Rank to User
		 *
		 * @since 2.5
		 * @version 1.0
		 */
		public function assign( $user_id = false ) {

			if ( $user_id === false || absint( $user_id ) === 0 ) {
				return false;
			}

			$user_id     = absint( $user_id );
			$old_rank_id = mycred_get_users_rank_by_type( $user_id, $this->type->term_id );

			mycred_update_user_meta( $user_id, 'mycred_rank_', $this->rank_id, current_time( 'timestamp' ) );
			mycred_update_user_meta( $user_id, 'mycred_current_rank_', $this->type->term_id, $this->rank_id );

			++$this->earners_count;

			mycred_update_post_meta( $this->rank_id, 'mycred_rank_earners_count', $this->earners_count );

			if ( ! empty( $old_rank_id ) ) {

				$old_rank_earners_count = mycred_get_post_meta( $old_rank_id, 'mycred_rank_earners_count', true );

				if ( ! empty( $old_rank_earners_count ) && $old_rank_earners_count > 0 ) {
					mycred_update_post_meta( $old_rank_id, 'mycred_rank_earners_count', ( $old_rank_earners_count - 1 ) );
				}
			}
		}

		public function display_rank( $atts, $user_id = null, $echo = false ) {

			if ( empty( $this->rank_id ) ) {
				return;
			}

			extract( $atts );

			wp_enqueue_style( 'mycred-rank-shortcodes' );

			$user_has_rank = $this->user_has_rank( $user_id );

			if ( ( ! empty( $excerpt ) && $excerpt == 1 ) ||
				( ! empty( $requirements ) && $requirements == 1 ) ||
				( ! empty( $earners ) && $earners == 1 )
			) {

				$html = '<div class="mycred-rank">';

				if ( ! empty( $image ) && $image == 1 ) {
					$html .= $this->display_image( $image_size, $user_has_rank );
				}

				$html .= '<div class="mycred-rank-detail">';

				if ( ! empty( $title ) && $title == 1 ) {
					$html .= $this->display_title( $title_link );
				}

				if ( ! empty( $excerpt ) && $excerpt == 1 ) {
					$html .= $this->display_excerpt();
				}

				if ( ! empty( $requirements ) && $requirements == 1 ) {
					$html .= $this->display_requirements( $user_id, $user_has_rank );
				}

				if ( ! empty( $earners ) && $earners == 1 ) {
					$html .= $this->display_earners( $user_has_rank, $earners_limit );
				}

				$html .= '</div>';
				$html .= '</div>';

			} else {

				$html = '<div class="mycred-rank basic">';

				if ( ! empty( $image ) && $image == 1 ) {
					$html .= $this->display_image( $image_size, $user_has_rank );
				}

				$html .= '<div class="mycred-rank-detail">';

				if ( ! empty( $title ) && $title == 1 ) {
					$html .= $this->display_title( $title_link );
				}

				$html .= '</div>';
				$html .= '</div>';

			}

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}

		public function display_image( $image_size = 80, $user_has_rank = false, $echo = false ) {

			if ( empty( $this->rank_id ) ) {
				return;
			}

			$html = '<div class="mycred-rank-image">';

			$img_attr = null;

			if ( ! $user_has_rank ) {
				$img_attr = array( 'class' => 'mycred-not-earned' );
			}

			if ( $image_size < 1 ) {
				$image_size = 80;
			}

			$html .= wp_kses_post( $this->get_logo_image( absint( $image_size ), $img_attr ) );

			$html .= '</div>';

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}

		public function display_title( $link = false, $echo = false ) {

			if ( empty( $this->rank_id ) ) {
				return;
			}

			$html = '<h3 class="mycred-rank-title">';

			if ( $link ) {
				$html .= '<a href="' . esc_url( get_permalink( $this->rank_id ) ) . '">' . esc_html( $this->title ) . '</a>';
			} else {
				$html .= esc_html( $this->title );
			}

			$html .= '</h3>';

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}

		public function display_excerpt( $echo = false ) {

			if ( empty( $this->rank_id ) ) {
				return;
			}

			$html = '<p class="mycred-rank-excerpt">' . esc_html( $this->post->post_excerpt ) . '</p>';

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}

		public function display_requirements( $user_id = null, $user_has_rank = false, $echo = false ) {

			if ( empty( $this->rank_id ) || empty( $this->requirements['requirements'] ) ) {
				return;
			}

			$rank_events  = mycred_get_rank_events();
			$list_element = empty( $this->requirements['is_sequential'] ) ? 'ul' : 'ol';
			$user_marks   = array();

			if ( ! $user_has_rank ) {

				$user_marks = mycred_get_user_meta( $user_id, 'mycred_rank_requirement_', $this->rank_id, true );

			}

			$html  = '<h6>' . __( 'Requirements', 'mycred' ) . '</h6>';
			$html .= '<' . $list_element . ' class="mycred-rank-requirements">';

			foreach ( $this->requirements['requirements'] as $key => $requirement ) {

				$label = ! empty( $requirement['label'] ) ? $requirement['label'] : 'No Label';

				$li_class = '';

				if ( $user_has_rank || ! empty( $user_marks ) && in_array( $requirement, $user_marks ) ) {

					$li_class = ' class="mycred-strike-off"';

				} else {

					$requirement_class = new $rank_events[ $requirement['reference'] ]['class']();

					if ( (bool) $requirement_class->has_met( $user_id, $requirement ) ) {

						$user_marks = mycred_mark_rank_requirement( $user_id, $this->rank_id, $requirement );
						$li_class   = ' class="mycred-strike-off"';

					}
				}

				$html .= '<li' . $li_class . '>';

				if ( ! empty( $requirement['url'] ) ) {

					$html .= '<a href="' . esc_url( $requirement['url'] ) . '">' . esc_html( $label ) . '</a>';

				} else {

					$html .= esc_html( $label );

				}
				$html .= '</li>';

			}

			$html .= '</' . $list_element . '>';

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}

		public function display_earners( $user_has_rank = false, $limit = 10, $display_name = false, $echo = false ) {

			if ( empty( $this->rank_id ) ) {
				return;
			}

			$users_args = array(
				'fields'     => array( 'ID', 'display_name' ),
				'meta_key'   => 'mycred_current_rank_' . $this->type->term_id,
				'meta_value' => $this->rank_id,
				'number'     => absint( $limit ),
			);

			$earners_list = get_users( $users_args );

			if ( empty( $earners_list ) ) {
				return;
			}

			$html  = '<h6>' . __( 'People who earned this:', 'mycred' ) . '</h6>';
			$html .= '<ul class="mycred-rank-earners">';

			foreach ( $earners_list as $earner ) {

				$html .= '<li>';
				$html .= '<img src="' . esc_url( get_avatar_url( $earner->ID ) ) . '" alt="' . esc_html( $earner->display_name ) . '" title="' . esc_html( $earner->display_name ) . '">';

				if ( $display_name ) {
					$html .= '<p>' . esc_html( $earner->display_name ) . '</p>';
				}

				$html .= '</li>';

			}

			$html .= '</ul>';

			if ( $echo ) {
				echo wp_kses_post( $html );
			} else {
				return $html;
			}
		}
	}
endif;
