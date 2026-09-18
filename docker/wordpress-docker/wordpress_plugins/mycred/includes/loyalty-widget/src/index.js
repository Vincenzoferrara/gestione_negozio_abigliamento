import { createRoot } from '@wordpress/element';
import App from './App';
import './index.scss';

const container = document.getElementById('mycred-loyalty-widget');

if (container) {
    const root = createRoot(container);
    root.render(<App />);
}
