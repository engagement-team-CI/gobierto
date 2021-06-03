/**
 * @jest-environment jsdom
 */

import { getVisualizationList } from "../../../app/javascript/gobierto_embeds/getVisualizationList.js";
import "@finos/perspective-viewer/dist/umd/perspective-viewer.js";
import "@finos/perspective-viewer-datagrid/dist/umd/perspective-viewer-datagrid.js";

beforeAll(async () => {
  const container = document.createElement('section')
  document.body.appendChild(container)
  const element = document.createElement('div');
  element.setAttribute('data-gobierto-visualization', '183');
  element.setAttribute('data-site', 'https://getafe.gobify.net');
  element.setAttribute('data-token', '1yvuaff8H2Ta5XGTYCXBhzUV');
  container.appendChild(element)
  await getVisualizationList(element)
});

describe('visualization', () => {
  test('render perspective', () => {
    const perspectiveViz = document.querySelector('perspective-viewer')
    perspectiveViz.setAttribute('plugin', 'datagrid')
    expect(document.querySelector('perspective-viewer')).not.toBeNull();
  })
})
