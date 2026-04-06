import DefaultTheme from 'vitepress/theme'
import './custom.css'
import DownloadButtons from './components/DownloadButtons.vue'
import ReleaseInfo from './components/ReleaseInfo.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('DownloadButtons', DownloadButtons)
    app.component('ReleaseInfo', ReleaseInfo)
  }
}
