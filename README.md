# react-native-inzori-applepay
React Native module to handle PassKit.

## Installation

### 1. Install library from `npm`

```shell
npm install --save react-native-inzori-applepay
```

### 2. Link native code

You can link native code in the way you prefer:

If you received error `jest-haste-map: Haste module naming collision: Duplicate module name: react-native`, add lines below to your Podfile and reinstall pods.

```diff
target 'YourProjectTarget' do

+   rn_path = '../node_modules/react-native'
+   pod 'yoga', path: "#{rn_path}/ReactCommon/yoga/yoga.podspec"
+   pod 'React', path: rn_path

  pod 'react-native-inzori-applepay', path: '../node_modules/react-native-inzori-applepay'

end

+ post_install do |installer|
+   installer.pods_project.targets.each do |target|
+     if target.name == "React"
+       target.remove_from_project
+     end
+   end
+ end
```

#### react-native link

Run command below:

```shell
react-native link react-native-inzori-applepay
```

## Usage

```jsx
import React, {Component} from 'react';
import {Platform, StyleSheet, Text, View} from 'react-native';
import PassKit, { AddPassButton } from 'react-native-inzori-applepay'

type Props = {};
export default class App extends Component<Props> {
  constructor(props) {
    super(props);
    const self = this;
    self.state = {
      isLoading: true,
      canAdd: false,
      error: false
    };    

  }

  componentDidMount() {
    // Add event listener
    PassKit.addEventListener('addPassesViewControllerDidFinish', this.onAddPassesViewControllerDidFinish)
    PassKit.addEventListener('addingPassSucceeded', this.onAddingPassSucceeded)
    PassKit.addEventListener('addingPassFailed', this.onAddingPassFailed)
    PassKit.addEventListener('addToWalletViewHidden', this.onAddToWalletViewHidden)

    setTimeout( () => {
      PassKit.isAvailable()
      .then((result)=>{
        console.log('is available: ' + result);
        if (!result) {
          throw new Error('PassKit payments not available');        
        }
        PassKit.canAddCard('3543')
      })
      .then((result) => {
        console.log('can add: ' + result);
        if(!result) {
          throw new Error('PassKit payments can not add cards'); 
        }
        this.setState({
          isLoading: false, 
          canAdd: result
        });
      })
      .catch((error) => {
        console.log('error');
        console.log(error);
        this.setState({
          isLoading: false, 
          canAdd: false,
          error: error.message
        });
      });
    },2000);
  }

  // To keep the context of 'this'
  onAddPassesViewControllerDidFinish = this.onAddPassesViewControllerDidFinish.bind(this)
  onAddingPassSucceeded = this.onAddingPassSucceeded.bind(this)
  onAddingPassFailed = this.onAddingPassFailed.bind(this)
  onAddToWalletViewHidden = this.onAddToWalletViewHidden.bind(this)

  componentWillUnmount() {
    // Remove event listener
    PassKit.removeEventListener('addPassesViewControllerDidFinish', this.onAddPassesViewControllerDidFinish)
    PassKit.removeEventListener('addingPassSucceeded', this.onAddingPassSucceeded)
    PassKit.removeEventListener('addingPassFailed', this.onAddingPassFailed)
    PassKit.removeEventListener('addToWalletViewHidden', this.onAddToWalletViewHidden)


  }

  onAddPassesViewControllerDidFinish() {
    console.log('App - onAddPassesViewControllerDidFinish')
  }
  onAddingPassSucceeded() {
    console.log('App - onAddingPassSucceeded')
  }
  onAddingPassFailed(obj) {
    console.log('App - onAddingPassFailed')
    console.log(obj)
  }
  onAddToWalletViewHidden() {
    console.log('App - onAddToWalletViewHidden')
  }      

  render() {
    const { isLoading, canAdd, error } = this.state;
    
    if (isLoading) {
      console.log('isLoading: ' + isLoading);
      return <Text style={styles.headline}>Loading...</Text>;
    } else if (!canAdd) {
      return <Text style={styles.headline}>{error}</Text>;
    }
      
    return <AddPassButton
      style={styles.button}
      addPassButtonStyle={PassKit.AddPassButtonStyle.black}       
      onPress={() => { 
        PassKit.presentAddPaymentPassViewController({
          apiEndpoint: 'http://app-dev.akimbocard.com:3000/api/v2/card/wallet/passdata',
          cardholderName: 'fabian martinez',
          localizedDescription:'Something here',
          paymentNetwork: 2,
          primaryAccountSuffix: '3543',
          primaryAccountIdentifier:'',
          authorization:'Bearer AiZlAPCLRMOhNE299bKzdg', // this is mutually exclusive with cookie
          cookie:'Cookie1 xyz',  // this is mutually exclusive with authorization
          userName: null
        }).then((result) => {console.log('done');});
      }}
    />;



    
    
  }
}

const styles = StyleSheet.create({
  button:{
    width: PassKit.AddPassButtonWidth,
    height: PassKit.AddPassButtonHeight,
    marginTop: 200
  },
  headline: {
    textAlign: 'center', // <-- the magic
    fontWeight: 'bold',
    fontSize: 18,
    marginTop: 220
  }
});
```

### Constants

- *PassKit.AddPassButtonStyle* - The appearance of the add-pass button
    - *black* - A black button with white lettering
    - *blackOutline* - A black button with a light outline
- *PassKit.AddPassButtonWidth* - Default add-pass button width
- *PassKit.AddPassButtonHeight* - Default add-pass button height
