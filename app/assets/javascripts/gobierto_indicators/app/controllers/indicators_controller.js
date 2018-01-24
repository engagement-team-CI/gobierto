this.GobiertoIndicators.IndicatorsController = (function() {

    function IndicatorsController() {}

    IndicatorsController.prototype.show = function() {
      _loadIndicator();
    };

    function _loadIndicator() {
      // define the item component
      Vue.component('item-tree', {
        template: '#item-tree-template',
        props: ['model'],
        data: function() {
          return {
            open: true
          }
        },
        computed: {
          hasChildren: function() {
            return this.model.children &&
              this.model.children.length
          }
        },
        methods: {
          toggle: function() {
            if (this.hasChildren) {
              this.open = !this.open
            }
          },
          viewDetail: function() {
            var ancestors = [];
            var parent = this.$parent;
            // get all my parents models
            while (parent.model !== undefined) {
              ancestors.push(parent.model);
              parent = parent.$parent;
            }
            this.$root.selected = _.extend(this.model, { ancestors: ancestors.reverse() });
          },
          getLevelClass: function(lvl) {
            return "item-lvl-" + lvl
          }
        }
      });

      // define the item view component
      Vue.component('item-view', {
        template: '#item-view-template',
        props: ['model'],
        data: function() {
          return {}
        },
        methods: {
          getLevelClass: function(lvl) {
            return "item-lvl-" + lvl
          }
        }
      });

      // define the item view wrap component
      Vue.component('item-view-wrap', {
        template: '#item-view-wrap-template',
        props: ['model'],
        data: function() {
          return {}
        },
        computed: {
          title: function() {
            var title = this.model.ancestors[0].attributes.title || '';
            if (this.model.ancestors.length > 0) this.model.ancestors.shift();
            return title;
          },
          hasAncestors: function() {
            return this.model.ancestors &&
              this.model.ancestors.length
          }
        },
        methods: {
          unselect: function() {
            return this.$root.selected = null;
          }
        }
      });

      var element = document.getElementById("indicator-form");

      var app = new Vue({
        el: '.indicators-tree',
        name: 'indicators-tree',
        data: function() {
          return {
            json: {},
            selected: null
          }
        },
        created: function() {
          this.getJson();
        },
        methods: {
          getJson: function() {
            this.json = JSON.parse(element.dataset.indicator);
          }
        }
      });
    };

    return IndicatorsController;
  })();

  this.GobiertoIndicators.indicators_controller = new GobiertoIndicators.IndicatorsController;
