(function (Drupal, once) {
  Drupal.behaviors.gsbcNavigation = {
    attach(context) {
      once('gsbc-navigation', '.nav-toggle', context).forEach((button) => {
        const navigation = document.getElementById(button.getAttribute('aria-controls'));
        const mobile = window.matchMedia('(max-width: 767px)');

        if (!navigation) return;

        const setExpanded = (expanded) => {
          button.setAttribute('aria-expanded', String(expanded));
          navigation.hidden = !expanded;
        };

        const syncViewport = () => setExpanded(!mobile.matches);

        button.addEventListener('click', () => {
          setExpanded(button.getAttribute('aria-expanded') !== 'true');
        });
        mobile.addEventListener('change', syncViewport);
        syncViewport();
      });
    },
  };
})(Drupal, once);
