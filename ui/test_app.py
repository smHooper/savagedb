import time

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.gridlayout import GridLayout
from kivy.core.window import WindowBase

root = Widget()
window_height = root.height
window_width = root.width

class PrintButton(Button):

    def on_touch_down(self, touch):
        print 'Hello'

class Menu(Widget):

    def __init__(self, **kwargs):
        super(Menu, self).__init__(**kwargs)
        self.height = 500
        self.width = 300
        self.center_x = root.center_x
        self.center_y = root.center_y



class LoginScreen(Menu):

    def __init__(self, **kwargs):
        super(LoginScreen, self).__init__(**kwargs)
        layout = GridLayout()
        layout.cols = 2
        layout.spacing = 50
        layout.row_default_height = window_height
        layout.col_default_width = window_width/10

        layout.add_widget(Label(text='Observer'))
        layout.observer_field = TextInput(multiline=False)
        layout.add_widget(layout.observer_field)

        layout.add_widget(Label(text='Box open'))
        layout.box_open_field = TextInput(box_open_field=True, multiline=False)
        layout.add_widget(layout.box_open_field)
        self.layout = layout
        self.add_widget(layout)

    def do_layout(self):
        self.layout.do_layout()
        '''self.cols = 2
        self.spacing = 50
        self.row_default_height = window_height/20
        self.col_default_width = window_width/10

        self.add_widget(Label(text='Observer'))
        self.observer_field = TextInput(multiline=False)
        self.add_widget(self.observer_field)

        self.add_widget(Label(text='Box open'))
        self.box_open_field = TextInput(box_open_field=True, multiline=False)
        self.add_widget(self.box_open_field)'''


class StartMenu(GridLayout):

    def __int__(self, **kwargs):
        super(StartMenu, self).__init__(**kwargs)
        self.cols = 2
        self.spacing = 50
        self.row_default_height = 100
        self.col_default_width = 400
        self.add_widget(Label(text='Observer'))
        self.observer_field = TextInput(multiline=False)
        self.add_widget(self.observer_field)
        self.add_widget(Label(text='Box open'))
        self.box_open = TextInput(multiline=False)
        self.add_widget(self.box_open)
        self.add_widget(Label(text='Box close'))
        self.box_close = TextInput(multiline=False)
        self.add_widget(self.box_open)



class Savage(App):
    def build(self):
        return LoginScreen()

    def printmessage(self, instance):
        print 'The button name "%s" was pressed' % instance.text

if __name__ == '__main__':
    Savage().run()