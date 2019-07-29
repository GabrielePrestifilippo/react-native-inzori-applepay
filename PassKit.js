/**
 * @flow
 */
'use strict'

import { NativeModules, NativeEventEmitter } from 'react-native'
import type EmitterSubscription from 'EmitterSubscription'

const nativeModule = NativeModules.RNPassKit
const nativeEventEmitter = new NativeEventEmitter(nativeModule)

export default {
  ...nativeModule,

  addPass: (base64Encoded: string, fileProvider?: string): Promise<void> => {
    return nativeModule.addPass(base64Encoded)
  },

  presentAddPaymentPassViewController: (args: Object): Promise<void> => {
    return nativeModule.presentAddPaymentPassViewController(args)
  },

  addEventListener: (
    eventType: string,
    listener: Function,
    context: ?Object,
  ): ?EmitterSubscription => (
    nativeEventEmitter.addListener(eventType, listener, context)
  ),

  removeEventListener: (eventType: string, listener: Function): void => {
    nativeEventEmitter.removeListener(eventType, listener)
  },
}
