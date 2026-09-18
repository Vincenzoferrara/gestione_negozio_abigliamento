import LuxuryLayout from './preview/layouts/LuxuryLayout';
import ModernLayout from './preview/layouts/ModernLayout';
import { normalizeLayoutTemplate } from './preview/templatePresets';

export default function HomeScreen({
    design,
    content,
    tabs,
    faq,
    user,
    isGuest,
    isPro,
    assetsUrl,
    ranksEnabled,
    badgesEnabled,
    onNavigate,
    onClose,
    previewMode = false,
}) {
    const borderRadius = design.borderRadius ?? 8;
    const layoutTemplate = normalizeLayoutTemplate(design.layoutTemplate);

    const handlePrimaryAction = () => {
        const url = isGuest ? content.joinRedirect : content.dashboardRedirect;
        if (url) window.location.href = url;
    };

    const handleLoginClick = () => {
        if (content.loginRedirect) window.location.href = content.loginRedirect;
    };

    const layoutProps = {
        design,
        content,
        tabs,
        faq,
        isGuest,
        user,
        assetsUrl,
        isPro,
        ranksEnabled,
        badgesEnabled,
        onNavigate,
        onClose,
        onPrimaryAction: handlePrimaryAction,
        onLoginClick: handleLoginClick,
        borderRadius,
        previewMode,
    };

    if (layoutTemplate === 'modern') {
        return <ModernLayout {...layoutProps} />;
    }

    return <LuxuryLayout {...layoutProps} />;
}
