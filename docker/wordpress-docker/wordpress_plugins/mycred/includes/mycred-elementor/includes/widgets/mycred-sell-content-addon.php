<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Content_Buyer_Count extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Buyer Count widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_content_buyer_count';
    }

    /**
     * Get widget title.
     *
     * Retrieve Buyer Count widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Buyers Count', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Buyer Count widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Buyer Count widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Buyer Count widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Buyers Count Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'wrapper', [
            'label' => __('Wrapper Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array(
                '' => __('Do not wrap', 'mycred'),
                'div' => 'DIV',
                'span' => 'SPAN',
                'p' => 'P',
                'h1' => 'H1',
                'h2' => 'H2',
                'h3' => 'H3',
                'h4' => 'H4',
                'h5' => 'H5',
                'h6' => 'H6'
            ),
            'default' => '',
            'description' => __('Option to change the element used to wrap around the value.', 'mycred')
                ]
        );

        $this->add_control(
                'post_id', [
            'label' => __('Post ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to provide a post ID.', 'mycred')
                ]
        );



        $this->end_controls_section();
    }

    /**
     * Render Buyer Count widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['wrapper'])) {
            $this->add_render_attribute('shortcode', 'wrapper', $settings['wrapper']);
        }
        if (!empty($settings['post_id'])) {
            $this->add_render_attribute('shortcode', 'post_id', $settings['post_id']);
        }
        $shortcode = do_shortcode('[mycred_content_buyer_count ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Content_Sale_Count extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Sale Count widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_content_sale_count';
    }

    /**
     * Get widget title.
     *
     * Retrieve Sale Count widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Sales Count', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Sale Count widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Sale Count widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Sale Count widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Sales Count Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'wrapper', [
            'label' => __('Wrapper Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array(
                '' => __('Do not wrap', 'mycred'),
                'div' => 'DIV',
                'span' => 'SPAN',
                'p' => 'P',
                'h1' => 'H1',
                'h2' => 'H2',
                'h3' => 'H3',
                'h4' => 'H4',
                'h5' => 'H5',
                'h6' => 'H6'
            ),
            'default' => '',
            'description' => __('Option to change the element used to wrap around the value.', 'mycred')
                ]
        );

        $this->add_control(
                'post_id', [
            'label' => __('Post ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to provide a post ID.', 'mycred')
                ]
        );



        $this->end_controls_section();
    }

    /**
     * Render Sale Count widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['wrapper'])) {
            $this->add_render_attribute('shortcode', 'wrapper', $settings['wrapper']);
        }
        if (!empty($settings['post_id'])) {
            $this->add_render_attribute('shortcode', 'post_id', $settings['post_id']);
        }
        $shortcode = do_shortcode('[mycred_content_sale_count ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Content_Buyer_Avatars extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Buy Avatars widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_content_buyer_avatars';
    }

    /**
     * Get widget title.
     *
     * Retrieve Buyer Avatars widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Buyer Avatars', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Buyer Avatars widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Buyer Avatars widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Buyer Avatars widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Buyer Avatars Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'post_id', [
            'label' => __('Post ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to provide a post ID.', 'mycred')
                ]
        );
        $this->add_control(
                'number', [
            'label' => __('Number', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '',
            'description' => __('The number of avatars to show.', 'mycred')
                ]
        );

        $this->add_control(
                'size', [
            'label' => __('Avatar Size', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The width and height of the avatars in pixels (without the px)', 'mycred')
                ]
        );

        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('Option to filter results by point type.', 'mycred')
                ]
        );

        $this->add_control(
                'use_email', [
            'label' => __('Use Email ?', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Show avatars based on their email instead of users ID', 'mycred')
                ]
        );

        $this->add_control(
                'default', [
            'label' => __('Default', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Default image to use. Requires an image URL.', 'mycred')
                ]
        );

        $this->add_control(
                'alt', [
            'label' => __('ALT', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to set the avatar images alt attribute.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Buyer Avatars widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }
        if (!empty($settings['size'])) {
            $this->add_render_attribute('shortcode', 'size', $settings['size']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }
        if (!empty($settings['post_id'])) {
            $this->add_render_attribute('shortcode', 'post_id', $settings['post_id']);
        }
        if (!empty($settings['default'])) {
            $this->add_render_attribute('shortcode', 'default', $settings['default']);
        }
        if (!empty($settings['alt'])) {
            $this->add_render_attribute('shortcode', 'alt', $settings['alt']);
        }

        $use_email = $settings['use_email'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'use_email', $use_email);


        $shortcode = do_shortcode('[mycred_content_buyer_avatars ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Sales_History extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Sales History widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_sales_history';
    }

    /**
     * Get widget title.
     *
     * Retrieve Sales History widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Sales History', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Sales History widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Sales History widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Sales History widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Sales History Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to show sales history for a particular user. Use "current" to show the user viewing this shortcode.', 'mycred')
                ]
        );


        $this->add_control(
                'number', [
            'label' => __('Number', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '',
            'description' => __('The number of purchases to show , use -1 to show all purchases.', 'mycred')
                ]
        );

        $this->add_control(
                'no_result', [
            'label' => __('No Purchases', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Text to show users if they have not yet made any purchases.', 'mycred')
                ]
        );


        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('Option to filter results by point type.', 'mycred')
                ]
        );

        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Purchase History order.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Sales History widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }
        if (!empty($settings['no_result'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['no_result']);
        }
        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }

        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }

        $shortcode = do_shortcode('[mycred_sales_history ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Sell_This extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Sell This widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_sell_this';
    }

    /**
     * Get widget title.
     *
     * Retrieve Sell This widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Sell This', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Sell This widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Sell This widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Render Sell This widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {
        $shortcode = do_shortcode('[mycred_sell_this]');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
