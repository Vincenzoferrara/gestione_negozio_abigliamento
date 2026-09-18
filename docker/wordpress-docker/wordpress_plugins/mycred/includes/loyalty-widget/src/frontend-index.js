import { createRoot } from '@wordpress/element';
import WidgetApp from './WidgetApp';

const container = document.getElementById('mycred-loyalty-widget-root');

if (container) {
    const root = createRoot(container);
    root.render(<WidgetApp />);
}
