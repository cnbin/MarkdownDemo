图片和音频文件发送的基本思路就是：

先将图片转化成二进制文件，然后将二进制文件进行base64编码，编码后成字符串。在即将发送的message内添加一个子节点，节点的

stringValue（节点的值）设置这个编码后的字符串。然后消息发出后取出消息文件的时候，通过messageType 先判断是不是图片信息，如果是

图片信息先通过自己之前设置的节点名称，把这个子节点的stringValue取出来，应该是一个base64之后的字符串，

往期回顾：

xmpp整理笔记：聊天信息的发送与显示  <http://www.cnblogs.com/dsxniubility/p/4307073.html>

xmpp整理笔记：环境的快速配置(附安装包)  <http://www.cnblogs.com/dsxniubility/p/4304570.html>

xmpp整理笔记：xmppFramework框架的导入和介绍  <http://www.cnblogs.com/dsxniubility/p/4307057.html>

xmpp整理笔记：用户网络连接及好友管理 <http://www.cnblogs.com/dsxniubility/p/4307066.html>

###一.图片发送

图片是通过界面的加号点击弹出相册界面，然后点击相册中的某张图片，相册退下，图片发出

    - (IBAction)setPhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];

    picker.delegate = self;

    [self presentViewController:picker animated:YES completion:nil];
    }

这是加号点击方法，之后设置UIImagePickerController的代理，然后再遵守对应的协议

这里需要注意的是，遵守了UIImagePickerControllerDelegate的 同时还必须要遵守 UINavigationControllerDelegate。协议

下面就是弹出相册点击了一张图片后触发的代理方法，都是常用方法在此也不过多解释。

    #pragma mark - ******************** imgPickerController代理方法
    - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
    {
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    NSData *data = UIImagePNGRepresentation(image);

    [self sendMessageWithData:data bodyName:@"image"];

    [self dismissViewControllerAnimated:YES completion:nil];
    }
其中的sendMessageWithData: bodyName: 是自定义的方法

此方法的功能就是传入一个data二进制文件 和 文件的类型，就把这个文件发出去。

之所有在后面有bodyName，让用户传入一个类型名，是为了区分发送图片和发送音频

方法内代码如下：

    /** 发送二进制文件 */
    - (void)sendMessageWithData:(NSData *)data bodyName:(NSString *)name
    {
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.chatJID];

    [message addBody:name];

    // 转换成base64的编码
    NSString *base64str = [data base64EncodedStringWithOptions:0];

    // 设置节点内容
    XMPPElement *attachment = [XMPPElement elementWithName:@"attachment" stringValue:base64str];

    // 包含子节点
    [message addChild:attachment];

    // 发送消息
    [[SXXMPPTools sharedXMPPTools].xmppStream sendElement:message];
    }

这个方法内流程就是一开始说得，先编码再发送。这个自定义的方法同样适用于发送音频信息。

###二.图片的显示
这个是在tableView数据源方法中，取出信息即将赋值之前多了一层判断，如果是图片信息，采用下面的方法赋值。

![img](http://ww1.sinaimg.cn/mw690/78f9859egw1evjq197isij20ag0j6tam.jpg)

关于基本发送流程哪里忘了可以查看普通文本信息的发送方法：

    if ([message.body isEqualToString:@"image"]) {
    XMPPMessage *msg = message.message;

    for (XMPPElement *node in msg.children) {

    // 取出消息的解码
    NSString *base64str = node.stringValue;
    NSData *data = [[NSData alloc]initWithBase64EncodedString:base64str options:0];
    UIImage *image = [[UIImage alloc]initWithData:data];

    // 把图片在label中显示
    NSTextAttachment *attach = [[NSTextAttachment alloc]init];
    attach.image = [image scaleImageWithWidth:200];
    NSAttributedString *attachStr = [NSAttributedString attributedStringWithAttachment:attach];

    // 用了这个label的属性赋值方法，就可以忽略那个普通的赋值方法
    cell.messageLabel.attributedText = attachStr;

    [self.view endEditing:YES];
    }
    }

这其中用到了一个 scaleImageWithWidth:方法，这个方法是传入一个允许的最大宽度width，然后这个方法内部先判断，如片大小是否超过最

大值，如果没有超过最大值就是图片有多大发多大，如果图片的尺寸超过了最大宽度，就把图片的整体尺寸都等比例缩小到正好等于最大宽度的

尺寸。这其中要用到Quartz2D的上下文的知识。

这个方法可以写成UIimage的分类，代码如下

    /** 把图片缩小到指定的宽度范围内为止 */
    - (UIImage *)scaleImageWithWidth:(CGFloat)width{
    if (self.size.width <width || width <= 0) {
    return self;
    }
    CGFloat scale = self.size.width/width;
    CGFloat height = self.size.height/scale;

    CGRect rect = CGRectMake(0, 0, width, height);

    // 开始上下文 目标大小是 这么大
    UIGraphicsBeginImageContext(rect.size);

    // 在指定区域内绘制图像
    [self drawInRect:rect];

    // 从上下文中获得绘制结果
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();

    // 关闭上下文返回结果
    UIGraphicsEndImageContext();
    return resultImage;
    }

###三.音频的发送

音频的发送，与之前图片的发送，有一定的相似，也有一些不同。音频发送的核心思想，是按下按钮开始录音，松开手结束录音并且保存录音。

因此需要处理按钮的按下和抬手两个监听方法。但是其中有一个苹果的bug: 自定义的按钮无法同时处理TouchUpInSide 和 TouchDown。 就是按

下按钮不松手是一个打印，手一松开一个打印。这是不行的，都是手一松两个同时打印。（除非按钮特别大，一般小按钮无法同时监听这两个点

击事件）。但是苹果自带的系统按钮却可以，不管多小，比如buttonWithTypeAdd（小加号按钮）都可以，因此设置点击声音按钮之后下面出现

一个inputView，上面是可以同时处理这两个时间的按钮。通过这个按钮来控制开始录音和结束录音。保存之后，也是转化成data二进制文件，

然后再通过base64编码。然后加入子节点，和图片类似发过去。接收的时候，也是取出节点内的stringValue解码。但是显示在tableview的cell

中的是声音的时间，点击这个cell触发声音播放时间。从而播放音频。播放时cell内部的某些样式变化也是可以控制的。

先把界面中的声音按钮的点击事件连线。

    - (IBAction)setRecord {
    // 切换焦点，弹出录音按钮
    [self.recordText becomeFirstResponder];
    }

其实就是自己随便写了个textField 点击时就让他获取焦点，然后下面弹出一个输入框上面有按钮

![img](http://ww4.sinaimg.cn/mw690/78f9859egw1evjq5ghqxbj20ae0j6q5b.jpg)

这个textField的懒加载如下

    - (UITextField *)recordText {
    if (_recordText == nil) {
    _recordText = [[UITextField alloc] init];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    _recordText.inputView = btn;

    [btn addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(stopRecord) forControlEvents:UIControlEventTouchUpInside];

    [self.inputMessageView addSubview:_recordText];
    }
    return _recordText;
    }


对于音频文件的一系列处理操作，最好抽出一个工具类写好，然后在需要的时候直接调用，并且以后其他项目也可以拖过去直接使用。

首先需要用到的属性如下。

    @interface SXRecordTools ()<AVAudioPlayerDelegate>

    /** 录音器 */
    @property(nonatomic,strong) AVAudioRecorder *recorder;

    /** 录音地址 */
    @property(nonatomic,strong) NSURL *recordURL;

    /** 播放器 */
    @property(nonatomic,strong) AVAudioPlayer *player;

    /** 播放完成时回调 */
    @property(nonatomic,copy) void (^palyCompletion)();
    @end
    至于其中的开始录音和结束录音方法如下

    /** 开始录音 */
    - (void)startRecord{
    [self.recorder record];
    }

    /** 停止录音 */
    - (void)stopRecordSuccess:(void (^)(NSURL *url,NSTimeInterval time))success andFailed:(void (^)())failed
    {
    // 只有在这里才能取到currentTime
    NSTimeInterval time = self.recorder.currentTime;
    [self.recorder stop];

    if (time < 1.5) {
    if (failed) {
    failed();
    }
    }else{
    if (success) {
    success(self.recordURL,time);
    }
    }
    }

开始录音和结束录音，框架中都自己有方法。主要是判断了一下，音频的时长，小于1.5秒会回调录音失败的代码块。

这里需要注意的是， recorder.currentTime 当前录音的时长，只有在这个方法中才能取到，出了方法就取不到值了。

然后在控制器中，那个小加号按钮的按下和抬起的监听方法中调用工具类中的方法

    #pragma mark - ******************** 录音方法
    - (void)startRecord {
    NSLog(@"开始录音");
    [[SXRecordTools sharedRecorder] startRecord];
    }

    - (void)stopRecord {
    NSLog(@"停止录音");
    [[SXRecordTools sharedRecorder] stopRecordSuccess:^(NSURL *url, NSTimeInterval time) {
    // 发送声音数据
    NSData *data = [NSData dataWithContentsOfURL:url];
    [self sendMessageWithData:data bodyName:[NSString stringWithFormat:@"audio:%.1f秒", time]];

    } andFailed:^{

    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"时间太短" delegate:nil cancelButtonTitle:@"确定" 

    otherButtonTitles:nil, nil] show];
    }];
    }

可以清楚的看到，发送声音调sendMessageWithData：时把声音的时长当做参数bodyName 传入。 然后就会将这个字符串存到message的子节点内发出。


###四.音频文件的显示
也是和图片一样，对于本行取出的信息先判断是不是音频信息，如果是，遍历节点，取出字符串，并且截取了一下，截取掉“audio：”，让

    tableView的cell中只显示 时长，

    else if ([message.body hasPrefix:@"audio"]){

    XMPPMessage *msg = message.message;

    for (XMPPElement *node in msg.children) {

    NSString *base64str = node.stringValue;

    NSData *data = [[NSData alloc]initWithBase64EncodedString:base64str options:0];

    NSString *newstr = [message.body substringFromIndex:6];
    cell.messageLabel.text = newstr;

    cell.audioData = data;
    }
    }
这个audioData是个专门用来存放声音文件的信息。但是表格是可以重用的，为了让一个刚刚重用的cell里面的音频文件别形成冲突，叠加。建议在刚取出cell时就加上一行

cell.audioData = nil;

###五关于声音文件的播放

虽然，框架自己就有声音文件的播放方法，但是还需要做很多附加操作，建议先在工具类中写一个方法，就是播放data文件，并且设置完成后的

回调代码。即playData:completion: 。在播放的方法中先判断声音是否正在播放，如果正在播放则不做任何操作。然后在方法中设置player的

代理，这样可以通过代理方法来监听声音文件何时播放完，触发代理方法。因此这个传入的completion代码块必须要先用成员变量记录下，然后

在声音文件播放完的代理方法中再执行此代码块

    - (void)playData:(NSData *)data completion:(void(^)())completion
    {
    // 判断是否正在播放
    if (self.player.isPlaying) {
    [self.player stop];
    }
    // 记录块代码
    self.palyCompletion = completion;

    // 监听播放器播放状态
    self.player = [[AVAudioPlayer alloc]initWithData:data error:NULL];
    self.player.delegate = self;
    [self.player play];
    }


代理方法在声音文件播放完的代理方法中再执行保存的代码块

    #pragma mark - ******************** 完成播放时的代理方法
    - (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
    {
    if (self.palyCompletion) {
    self.palyCompletion();
    }
    }


工具类中的方法写完了之后，可以去外面调用了。给自己这个自定义的SXChatCell添加一个点击方法。默认情况下按钮是默认颜色的，点击时颜

色变成红色，然后播放完成时的回调代码再把颜色恢复成默认颜色。

    - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // 如果有音频数据，直接播放音频
    if (self.audioData != nil) {
    // 播放音频
    self.messageLabel.textColor = [UIColor redColor];
    // 如果单例的块代码中包含self，一定使用weakSelf
    __weak SXChatCell *weakSelf = self;
    [[SXRecordTools sharedRecorder] playData:self.audioData completion:^{
    weakSelf.messageLabel.textColor = [UIColor blackColor];
    }];
    }
    }

如图红色的那个cell是正在播放

![img](http://ww4.sinaimg.cn/mw690/78f9859egw1evjq5cm80lj20ae0j5q4s.jpg)