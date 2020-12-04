// TODO: traducir con I18n
export const Widgets = {
  HTML: {
    name: "Contenido HTML",
    template: () => import("../components/WidgetHTML"),
    w: 6,
    h: 3,
    minW: 4,
  },
  INDICATOR: {
    name: "Indicador",
    template: () => import("../components/WidgetIndicator"),
    w: 6,
    h: 5,
    minW: 4,
    minH: 3,
    subtypes: {
      individual: {
        name: "Individual",
        template: () => import("../components/WidgetIndicatorIndividual")
      },
      table: {
        name: "Tabla",
        template: () => import("../components/WidgetIndicatorTable")
      }
    }
  }
};
